import SwiftUI
import AlarmKit

struct SettingsTab: View {
    @Binding var event: Event
    @State var primaryClr: Color = Color.blue
    @State var secondaryClr: Color = Color.green
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    @State private var isAlarmOn = false
    @State private var alarmID: UUID?
    @State private var alarmOffset: TimeInterval = 0
    
    // Picker options: 0 to 24h before event, minute granularity.
    private let maxOffsetMinutes = 24 * 60
    private var offsetOptions: [Int] { Array(0...maxOffsetMinutes) }
    
    // Computed alarm fire date, or nil if offset would be before now.
    private var computedAlarmDate: Date? {
        guard let proposed = Calendar.current.date(byAdding: .second, value: Int(-alarmOffset), to: event.eventDate),
              proposed >= Date() else {
            return nil
        }
        return proposed
    }
    
    private func cancelExistingAlarm() async {
        if let alarmID {
            do {
                try AlarmManager.shared.cancel(id: alarmID)
                print("🔕 Cancelled alarm with id: \(alarmID)")
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
            stopButton: AlarmButton(text: "Dismiss", textColor: .white, systemImageName: "stop.fill")
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
            let alarm = try await AlarmManager.shared.schedule(id: newAlarmID, configuration: configuration)
            alarmID = newAlarmID
            print("✅ Scheduled alarm '\(event.title)' for \(alarmDate.formatted(date: .numeric, time: .shortened)) with id: \(alarm.id)")
        } catch {
            print("❌ Failed to schedule alarm:", error)
        }
    }
    
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
                        .overlay(RoundedRectangle(cornerRadius: 45).stroke(Color.gray.opacity(0.4)).blur(radius: 20.0))
                }
                .onChange(of: event.emoji) {
                    event.saveToDatabase()
                }
                
                DatePicker("Event Date & Time", selection: $event.eventDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .onChange(of: event.eventDate) {
                        event.saveToDatabase()
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
                            }
                        }
                    }
                
                Picker("Alarm Offset (min before event)", selection: $alarmOffset) {
                    ForEach(offsetOptions, id: \.self) { minutes in
                        if let proposedDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: event.eventDate),
                           proposedDate >= Date() {
                            Text("\(minutes) min before").tag(TimeInterval(minutes * 60))
                        } else {
                            // Blank for invalid offsets before current time
                            Text(" ").tag(TimeInterval(minutes * 60))
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
        }
    }
}
