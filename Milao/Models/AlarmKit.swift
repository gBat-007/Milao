import AlarmKit
import SwiftUI

nonisolated struct EventAlarmMetadata: AlarmMetadata {}

func scheduleAlarm(for event: Event) async {
    let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: event.title),
        stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")
    )
    let presentation = AlarmPresentation(alert: alert)

    let attributes = AlarmAttributes<EventAlarmMetadata>(
        presentation: presentation,
        metadata: EventAlarmMetadata(),
        tintColor: .red
    )

    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: nil,
        schedule: .fixed(event.eventDate),
        attributes: attributes
    )

    let alarmID = UUID()
    do {
        let alarm = try await AlarmManager.shared.schedule(
            id: alarmID,
            configuration: configuration
        )
        print("✅ Scheduled alarm '\(event.title)' with id: \(alarm.id)")
    } catch {
        print("❌ Failed to schedule alarm:", error)
    }
}
