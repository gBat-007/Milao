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
            WCSession.default.sendMessage(["request": "events"], replyHandler: nil, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["events"] as? Data,
           let decoded = try? JSONDecoder().decode([WidgetEvent].self, from: data) {
            DispatchQueue.main.async {
                self.events = decoded
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
