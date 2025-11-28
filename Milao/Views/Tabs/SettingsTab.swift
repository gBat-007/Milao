import SwiftUI
import AlarmKit
internal import Combine
import FirebaseFirestore

// MARK: - Cache model

struct CachedAlarm: Codable {
    let eventID: String
    let eventName: String
    let alarmDate: Date
    var isActive: Bool
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

    func saveAlarm(eventID: String, eventName: String, alarmDate: Date, isActive: Bool) {
        var alarms = cachedAlarms
        alarms.removeAll { $0.eventID == eventID }
        alarms.append(CachedAlarm(eventID: eventID,
                                  eventName: eventName,
                                  alarmDate: alarmDate,
                                  isActive: isActive))
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
    @State private var firestoreListener: ListenerRegistration?
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
        if let alarmID {
            do {
                try AlarmManager.shared.cancel(id: alarmID)
                print("🔕 Cancelled alarm with id: \(alarmID)")

                if let eventID = selectedEventID {
                    cache.removeAlarm(eventID: eventID)
                }
            } catch {
                print("❌ Failed to cancel alarm:", error)
            }
        }
    }

    private func scheduleAlarmAtComputedDate() async {
        await cancelExistingAlarm()

        guard let alarmDate = computedAlarmDate else {
            print("⚠️ Invalid alarm date; cannot schedule alarm before now")
            return
        }

        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: event.title),
            stopButton: AlarmButton(
                text: "Dismiss",
                textColor: .white,
                systemImageName: "stop.fill"
            )
        )
        let presentation = AlarmPresentation(alert: alert)

        let metadata = EventAlarmMetadata(
            id: event.id,
            title: event.title,
            emoji: event.emoji
        )

        let attributes = AlarmAttributes<EventAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: .orange
        )

        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: .fixed(alarmDate),
            attributes: attributes
        )

        let newAlarmID = UUID()
        do {
            let alarm = try await AlarmManager.shared.schedule(
                id: newAlarmID,
                configuration: configuration
            )
            alarmID = newAlarmID
            cachedAlarmDate = alarmDate
            print("✅ Scheduled alarm '\(event.title)' for \(alarmDate.formatted(date: .numeric, time: .shortened)) with id: \(alarm.id)")

            if let eventID = selectedEventID {
                cache.saveAlarm(eventID: eventID,
                                eventName: event.title,
                                alarmDate: alarmDate,
                                isActive: true)
            }
        } catch {
            print("❌ Failed to schedule alarm:", error)
        }
    }

    private func refreshEvent() {
        print("🔄 Refreshing event from Firestore update")
        // Dynamic Island / Live Activity refresh here
    }

    private func setupFirestoreListener() {
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document(event.id)

        firestoreListener = eventRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firestore listener error:", error)
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("❌ Event document no longer exists")
                return
            }

            do {
                let updatedEvent = try snapshot.data(as: Event.self)
                print("🔄 Event updated from Firestore: \(updatedEvent.title)")
                event = updatedEvent
                primaryClr = updatedEvent.bgColor1.color
                secondaryClr = updatedEvent.bgColor2.color
                refreshEvent()

                if let eventID = selectedEventID,
                   isAlarmOn,
                   let alarmDate = cachedAlarmDate {
                    cache.saveAlarm(eventID: eventID,
                                    eventName: updatedEvent.title,
                                    alarmDate: alarmDate,
                                    isActive: true)
                }
            } catch {
                print("❌ Failed to decode event from Firestore:", error)
            }
        }
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
                        Task {
                            if newValue {
                                await scheduleAlarmAtComputedDate()
                            } else {
                                await cancelExistingAlarm()
                                alarmID = nil
                                if let eventID = selectedEventID {
                                    cache.removeAlarm(eventID: eventID)
                                }
                            }
                        }
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
                    Task {
                        if isAlarmOn {
                            await scheduleAlarmAtComputedDate()
                        }
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
            setupFirestoreListener()
            restoreCachedAlarmState()
        }
        .onDisappear {
            firestoreListener?.remove()
        }
    }
}
