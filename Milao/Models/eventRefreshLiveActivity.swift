import Foundation

final class EventsRefresh {

    static let shared = EventsRefresh()   // optional but recommended
    private init() {}

    /// Refreshes the currently active Live Activity event
    func refreshEvent(events: [Event]) {
        guard let id = EventManager.shared.activeLiveActivityEventID else {
            print("❌ No cached active Live Activity ID found.")
            return
        }

        guard let event = events.first(where: { $0.id == id }) else {
            print("❌ Could not find event with id: \(id)")
            return
        }

        print("🔄 Refreshing Live Activity for cached event: \(event.title) (\(event.id))")
        print("The cached event info is \(event.title) \(event.emoji) (\(event.id))")

        TimerManager.shared.updateSimpleTimer(
            to: event.newWidgetEvent(event: event)
        )
    }
}
