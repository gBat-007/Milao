import SwiftUI
import AlarmKit
internal import Combine
import FirebaseAuth
import FirebaseDatabase

// MARK: - Cache model

struct CachedAlarm: Codable {
    let eventID: String
    let eventName: String
    let alarmDate: Date
    var isActive: Bool
    var alarmID: UUID? = nil
}

// MARK: - Cache manager

final class AlarmCacheManager {
    static let shared = AlarmCacheManager()
    private init() {}

    @AppStorage("cachedAlarms") private var cachedAlarmsData: Data = Data()

    var cachedAlarms: [CachedAlarm] {
        get {
            (try? JSONDecoder().decode([CachedAlarm].self, from: cachedAlarmsData)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                cachedAlarmsData = data
            }
        }
    }

    func getCachedAlarm(for eventID: String) -> CachedAlarm? {
        cachedAlarms.first { $0.eventID == eventID }
    }

    func saveAlarm(eventID: String, eventName: String, alarmDate: Date, isActive: Bool, alarmID: UUID? = nil) {
        var alarms = cachedAlarms
        alarms.removeAll { $0.eventID == eventID }
        alarms.append(CachedAlarm(eventID: eventID,
                                  eventName: eventName,
                                  alarmDate: alarmDate,
                                  isActive: isActive,
                                  alarmID: alarmID))
        cachedAlarms = alarms
    }

    func removeAlarm(eventID: String) {
        var alarms = cachedAlarms
        alarms.removeAll { $0.eventID == eventID }
        cachedAlarms = alarms
    }

    func updateAlarmStatus(eventID: String, isActive: Bool) {
        var alarms = cachedAlarms
        if let idx = alarms.firstIndex(where: { $0.eventID == eventID }) {
            alarms[idx].isActive = isActive
            cachedAlarms = alarms
        }
    }
}

// MARK: - View

struct SettingsTab: View {
    @Binding var event: Event
    @State var primaryClr: Color = .blue
    @State var secondaryClr: Color = .green
    @EnvironmentObject var viewModel: AuthenticationViewModel

    @State private var isAlarmOn: Bool = false
    @State private var alarmID: UUID? = nil
    @State private var alarmOffset: TimeInterval = 0
    @State private var alarmSettingsListener: DatabaseHandle?
    @State private var selectedEventID: String? = nil
    @State private var selectedEventName: String = ""
    @State private var cachedAlarmDate: Date? = nil

    private let cache = AlarmCacheManager.shared

    // Picker options: 0 to 24h before event, minute granularity.
    private let maxOffsetMinutes = 24 * 60
    private var offsetOptions: [Int] { Array(0...maxOffsetMinutes) }

    // Computed alarm fire date, or nil if offset would be before now.
    private var computedAlarmDate: Date? {
        guard let proposed = Calendar.current.date(
            byAdding: .second,
            value: Int(-alarmOffset),
            to: event.eventDate
        ),
        proposed >= Date() else {
            return nil
        }
        return proposed
    }

    // MARK: - Cache helpers (using manager)

    private var alarmSettingsRef: DatabaseReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Database.database().reference()
            .child("users").child(uid).child("alarmSettings").child(event.id)
    }

    private func persistAlarmSettings(enabled: Bool, offset: TimeInterval) {
        let values: [String: Any] = [
            "enabled": enabled,
            "offsetMinutes": Int(offset / 60)
        ]
        alarmSettingsRef?.setValue(values)
    }

    private func setupAlarmSettingsListener() {
        guard let ref = alarmSettingsRef else { return }
        alarmSettingsListener = ref.observe(.value) { snapshot in
            let values = snapshot.value as? [String: Any] ?? [:]
            let enabled = values["enabled"] as? Bool ?? false
            let offset = TimeInterval(values["offsetMinutes"] as? Int ?? 0) * 60
            guard enabled != isAlarmOn || offset != alarmOffset else { return }

            // AlarmSyncManager owns native scheduling; this listener only mirrors
            // the shared preference into the controls on this device.
            isAlarmOn = enabled
            alarmOffset = offset
        }
    }

    private func restoreCachedAlarmState() {
        guard let eventID = selectedEventID else { return }

        if let cached = cache.getCachedAlarm(for: eventID) {
            if cached.isActive && cached.alarmDate > Date() {
                isAlarmOn = true
                cachedAlarmDate = cached.alarmDate
                selectedEventName = cached.eventName
                let diff = event.eventDate.timeIntervalSince(cached.alarmDate)
                alarmOffset = max(0, diff)
            } else {
                cache.removeAlarm(eventID: eventID)
                isAlarmOn = false
                cachedAlarmDate = nil
            }
        } else {
            isAlarmOn = false
            cachedAlarmDate = nil
        }
    }

    // MARK: - Alarm logic

    private func cancelExistingAlarm() async {
        let cachedID = selectedEventID.flatMap { cache.getCachedAlarm(for: $0)?.alarmID }
        guard let alarmID = alarmID ?? cachedID else { return }
        do {
            try AlarmManager.shared.cancel(id: alarmID)
            print("🔕 Cancelled alarm with id: \(alarmID)")
            self.alarmID = nil
            if let eventID = selectedEventID {
                cache.removeAlarm(eventID: eventID)
            }
        } catch {
            print("❌ Failed to cancel alarm:", error)
        }
    }

    private func scheduleAlarmAtComputedDate() async {
        await cancelExistingAlarm()

        guard let alarmDate = computedAlarmDate else {
            print("⚠️ Invalid alarm date; cannot schedule alarm before now")
            return
        }

        guard let scheduledAlarmID = await scheduleAlarm(for: event, at: alarmDate) else { return }
        alarmID = scheduledAlarmID
        cachedAlarmDate = alarmDate

        if let eventID = selectedEventID {
            cache.saveAlarm(eventID: eventID,
                            eventName: event.title,
                            alarmDate: alarmDate,
                            isActive: true,
                            alarmID: scheduledAlarmID)
        }
    }

    private func refreshEvent() {
        print("🔄 Refreshing event from Firestore update")
        // Dynamic Island / Live Activity refresh here
    }

    private func setupEventAlarmSettingsListener() {
        setupAlarmSettingsListener()
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                ColorPicker("Primary Color", selection: $primaryClr)
                ColorPicker("Secondary Color", selection: $secondaryClr)
            }
            .onChange(of: primaryClr) {
                event.bgColor1 = CodableColor(color: primaryClr)
                event.saveToDatabase()
            }
            .onChange(of: secondaryClr) {
                event.bgColor2 = CodableColor(color: secondaryClr)
                event.saveToDatabase()
            }

            Section(header: Text("Event Info")) {
                HStack {
                    Text("Emoji ")
                        .fontDesign(.rounded)
                    EmojiKeyboardButton(emoji: $event.emoji)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 45)
                                .stroke(Color.gray.opacity(0.4))
                                .blur(radius: 20.0)
                        )
                }
                .onChange(of: event.emoji) {
                    event.saveToDatabase()
                }

                DatePicker(
                    "Event Date & Time",
                    selection: $event.eventDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .onChange(of: event.eventDate) {
                    event.saveToDatabase()
                    if let eventID = selectedEventID,
                       let cached = cache.getCachedAlarm(for: eventID) {
                        cachedAlarmDate = cached.alarmDate
                        let diff = event.eventDate.timeIntervalSince(cached.alarmDate)
                        alarmOffset = max(0, diff)
                    }
                }
            }

            Section(header: Text("Alarm Settings")) {
                Toggle("Alarm", isOn: $isAlarmOn)
                    .onChange(of: isAlarmOn) { _, newValue in
                        persistAlarmSettings(enabled: newValue, offset: alarmOffset)
                    }

                Picker("Alarm Offset (min before event)", selection: $alarmOffset) {
                    ForEach(offsetOptions, id: \.self) { minutes in
                        if let proposedDate = Calendar.current.date(
                            byAdding: .minute,
                            value: -minutes,
                            to: event.eventDate
                        ),
                        proposedDate >= Date() {
                            Text("\(minutes) min before")
                                .tag(TimeInterval(minutes * 60))
                        } else {
                            Text(" ")
                                .tag(TimeInterval(minutes * 60))
                        }
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(height: 100)
                .onChange(of: alarmOffset) { _ in
                    if isAlarmOn {
                        persistAlarmSettings(enabled: true, offset: alarmOffset)
                    }
                }

                if let alarmDate = computedAlarmDate {
                    Text("Alarm time: \(alarmDate.formatted(date: .numeric, time: .shortened))")
                        .font(.footnote)
                        .foregroundColor(.primary)
                } else {
                    Text("Alarm time: Invalid (before current time)")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            primaryClr = event.bgColor1.color
            secondaryClr = event.bgColor2.color
            selectedEventID = event.id
            selectedEventName = event.title
            setupEventAlarmSettingsListener()
        }
        .onDisappear {
            if let alarmSettingsListener, let ref = alarmSettingsRef {
                ref.removeObserver(withHandle: alarmSettingsListener)
            }
        }
    }
}
