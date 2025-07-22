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

    // Push data to watch
    func send(widgetEvents: [WidgetEvent]) {
        guard WCSession.default.isReachable else {
            print("⚠️ Watch is not reachable")
            return
        }

        print("📤 Sending \(widgetEvents.count) WidgetEvents to Watch")

        if let data = try? JSONEncoder().encode(widgetEvents) {
            WCSession.default.sendMessage(["events": data], replyHandler: nil, errorHandler: { error in
                print("❌ Watch send failed: \(error.localizedDescription)")
            })
        }
    }

    // When watch requests events
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if message["request"] as? String == "events" {
            print("📬 Watch requested events")

            let widgetEvents = WidgetEventStore.shared.widgetEvents

            guard !widgetEvents.isEmpty else {
                print("⚠️ WidgetEvents not ready yet. Skipping send.")
                return
            }

            send(widgetEvents: widgetEvents)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("✅ Session activated with state: \(activationState.rawValue)")
        if let error = error {
            print("❌ Activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 WCSession deactivated. Re-activating...")
        WCSession.default.activate()
    }
}
