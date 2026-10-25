import AlarmKit
import SwiftUI
import ActivityKit
import WidgetKit
import FirebaseAuth
import FirebaseDatabase

func scheduleAlarm(for event: Event, at fireDate: Date? = nil) async -> UUID? {
    let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: event.title),
        stopButton: AlarmButton(
            text: "Dismiss",
            textColor: .white,
            systemImageName: "stop.fill"
        )
    )

    let presentation = AlarmPresentation(alert: alert)
    let metadata = EventAlarmMetadata(id: event.id, title: event.title, emoji: event.emoji)
    let attributes = AlarmAttributes<EventAlarmMetadata>(
        presentation: presentation,
        metadata: metadata,
        tintColor: .orange
    )
    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: nil,
        schedule: .fixed(fireDate ?? event.eventDate),
        attributes: attributes
    )

    let alarmIDKey = "milao.alarmID.\(event.id)"
    if let oldIDString = UserDefaults.standard.string(forKey: alarmIDKey),
       let oldID = UUID(uuidString: oldIDString) {
        try? AlarmManager.shared.cancel(id: oldID)
    }

    let alarmID = UUID()
    do {
        let authorization = try await AlarmManager.shared.requestAuthorization()
        guard authorization == .authorized else {
            print("⚠️ Alarm authorization was not granted for \(event.id)")
            return nil
        }
        let alarm = try await AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
        UserDefaults.standard.set(alarmID.uuidString, forKey: alarmIDKey)
        print("✅ Scheduled alarm '\(event.title)' with id: \(alarm.id)")
        return alarmID
    } catch {
        print("❌ Failed to schedule alarm:", error)
        return nil
    }
}

func cancelScheduledAlarm(eventID: String) async {
    let key = "milao.alarmID.\(eventID)"
    AlarmCacheManager.shared.removeAlarm(eventID: eventID)
    guard let idString = UserDefaults.standard.string(forKey: key),
          let id = UUID(uuidString: idString) else { return }
    do {
        try AlarmManager.shared.cancel(id: id)
    } catch {
        print("❌ Failed to cancel alarm for event \(eventID):", error)
    }
    UserDefaults.standard.removeObject(forKey: key)
}

@MainActor
final class AlarmSyncManager {
    static let shared = AlarmSyncManager()
    private var settingsRef: DatabaseReference?
    private var listener: DatabaseHandle?
    private var observedUID: String?
    private var authListener: AuthStateDidChangeListenerHandle?
    private var eventListeners: [String: (DatabaseReference, DatabaseHandle)] = [:]
    private var offsetsByEventID: [String: Int] = [:]

    private init() {}

    func start() {
        guard authListener == nil else { return }
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                if let uid = user?.uid {
                    self.observeSettings(for: uid)
                } else {
                    let eventIDs = Array(self.eventListeners.keys)
                    self.stopSettings()
                    self.stopEventListeners()
                    for eventID in eventIDs {
                        await cancelScheduledAlarm(eventID: eventID)
                    }
                    self.observedUID = nil
                }
            }
        }
    }

    private func observeSettings(for uid: String) {
        guard Auth.auth().currentUser?.uid == uid, uid != observedUID else { return }
        stopSettings()
        stopEventListeners()
        observedUID = uid
        let ref = Database.database().reference().child("users").child(uid).child("alarmSettings")
        settingsRef = ref
        listener = ref.observe(.value) { [weak self] snapshot in
            let settings = snapshot.children.compactMap { child -> (String, Bool, Int)? in
                guard let child = child as? DataSnapshot,
                      let values = child.value as? [String: Any] else { return nil }
                return (child.key, values["enabled"] as? Bool ?? false,
                        max(0, values["offsetMinutes"] as? Int ?? 0))
            }
            Task { @MainActor in
                guard let self else { return }
                let settingsByID = Dictionary(uniqueKeysWithValues: settings.map { ($0.0, ($0.1, $0.2)) })
                for eventID in Array(self.eventListeners.keys) where settingsByID[eventID] == nil || settingsByID[eventID]?.0 == false {
                    self.removeEventListener(for: eventID)
                    await cancelScheduledAlarm(eventID: eventID)
                }
                for (eventID, enabled, offset) in settings {
                    guard enabled else {
                        await cancelScheduledAlarm(eventID: eventID)
                        continue
                    }
                    self.offsetsByEventID[eventID] = offset
                    self.observeEventIfNeeded(eventID)
                }
            }
        }
    }

    private func observeEventIfNeeded(_ eventID: String) {
        guard eventListeners[eventID] == nil else { return }
        let ref = Database.database().reference().child("events").child(eventID)
        let handle = ref.observe(.value) { snapshot in
            guard let values = snapshot.value as? [String: Any],
                  JSONSerialization.isValidJSONObject(values),
                  let data = try? JSONSerialization.data(withJSONObject: values) else {
                Task { @MainActor in await cancelScheduledAlarm(eventID: eventID) }
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard var event = try? decoder.decode(Event.self, from: data) else { return }
            event.id = eventID
            Task { @MainActor in
                let offset = max(0, self.offsetsByEventID[eventID] ?? 0)
                let fireDate = event.eventDate.addingTimeInterval(TimeInterval(-offset * 60))
                guard fireDate > Date() else {
                    await cancelScheduledAlarm(eventID: eventID)
                    return
                }
                if let alarmID = await scheduleAlarm(for: event, at: fireDate) {
                    AlarmCacheManager.shared.saveAlarm(
                        eventID: eventID,
                        eventName: event.title,
                        alarmDate: fireDate,
                        isActive: true,
                        alarmID: alarmID
                    )
                }
            }
        }
        eventListeners[eventID] = (ref, handle)
    }

    private func removeEventListener(for eventID: String) {
        if let (ref, handle) = eventListeners.removeValue(forKey: eventID) {
            ref.removeObserver(withHandle: handle)
        }
        offsetsByEventID.removeValue(forKey: eventID)
    }

    private func stopSettings() {
        if let listener, let settingsRef {
            settingsRef.removeObserver(withHandle: listener)
        }
        listener = nil
        settingsRef = nil
    }

    private func stopEventListeners() {
        for eventID in Array(eventListeners.keys) { removeEventListener(for: eventID) }
    }

    func stop() {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
        authListener = nil
        stopSettings()
        stopEventListeners()
        observedUID = nil
    }
}
