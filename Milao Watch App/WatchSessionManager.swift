import Foundation
import WatchConnectivity
internal import Combine

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var events: [WidgetEvent] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func requestEvents() {
        if WCSession.default.isReachable {
            print("📨 Sending request to iPhone for events...")
            WCSession.default.sendMessage(["request": "events"], replyHandler: nil, errorHandler: { error in
                print("❌ Failed to request events from iPhone: \(error.localizedDescription)")
            })
        } else {
            print("⚠️ iPhone is not reachable from Watch")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["events"] as? Data {
            print("📥 Received events from iPhone")

            if let decoded = try? JSONDecoder().decode([WidgetEvent].self, from: data) {
                DispatchQueue.main.async {
                    self.events = decoded
                }
                print("✅ Decoded \(decoded.count) WidgetEvents")
            } else {
                print("❌ Failed to decode events")
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("📶 Watch session activated")
    }
}
