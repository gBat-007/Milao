import AlarmKit
import SwiftUI
import ActivityKit
import WidgetKit

func scheduleAlarm(for event: Event) async {
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
        tintColor: .orange // Optional: match bgColor1 if you'd like
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

