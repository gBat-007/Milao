import Foundation
import WatchConnectivity

class PhoneSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = PhoneSessionManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(events: [Event]) {
        let widgets = events.map {
            WidgetEvent(
                id: $0.id,
                title: $0.title,
                emoji: $0.emoji,
                eventDate: $0.eventDate,
                memberCount: $0.membersNum,
                placesNum: $0.placesNum
            )
        }

        if WCSession.default.isReachable,
           let data = try? JSONEncoder().encode(widgets) {
            WCSession.default.sendMessage(["events": data], replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("✅ Session activated with state: \(activationState.rawValue)")
        if let error = error {
            print("❌ Activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ WCSession became inactive. Possibly switching to another paired watch.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 WCSession deactivated. Re-activating session...")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if message["request"] as? String == "events" {
            print("📬 Received request for events from Watch")

            // You'll need access to the current events array here:
            let eventsToSend = myEvents  // 👈 Replace with your actual source

            let widgets = eventsToSend.map { $0.asWidgetEvent }

            if let data = try? JSONEncoder().encode(widgets) {
                WCSession.default.sendMessage(["events": data], replyHandler: nil, errorHandler: { error in
                    print("❌ Failed to send events to Watch: \(error.localizedDescription)")
                })
            } else {
                print("❌ Encoding [WidgetEvent] failed")
            }
        }
    }
}
