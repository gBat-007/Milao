import Foundation

class EventManager {
    static let shared = EventManager()
    
    private let userDefaults = UserDefaults.standard
    private let activeLiveActivityEventIDKey = "activeLiveActivityEventID"
    private let selectedEventIDKey = "selectedEventID"
    
    // MARK: - Active Live Activity Event ID (Cached as String)
    var activeLiveActivityEventID: String? {
        get {
            userDefaults.string(forKey: activeLiveActivityEventIDKey)
        }
        set {
            if let id = newValue {
                userDefaults.set(id, forKey: activeLiveActivityEventIDKey)
            } else {
                userDefaults.removeObject(forKey: activeLiveActivityEventIDKey)
            }
        }
    }
    
    // MARK: - Selected Event ID (Cached as String)
    var selectedEventID: String? {
        get {
            userDefaults.string(forKey: selectedEventIDKey)
        }
        set {
            if let id = newValue {
                userDefaults.set(id, forKey: selectedEventIDKey)
            } else {
                userDefaults.removeObject(forKey: selectedEventIDKey)
            }
        }
    }
    
    // MARK: - Clear Active Event Cache
    func clearActiveEvent() {
        userDefaults.removeObject(forKey: activeLiveActivityEventIDKey)
    }
    
    private init() {}
}
