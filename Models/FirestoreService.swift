import FirebaseDatabase
import Foundation

func saveEventRDB(_ event: Event, completion: @escaping (Result<Void, Error>) -> Void) {
    let ref = Database.database().reference()
    let id = event.id ?? UUID().uuidString
    let eventRef = ref.child("events").child(id)

    var eventToSave = event
    eventToSave.id = id

    do {
        let data = try JSONEncoder().encode(eventToSave)
        if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            eventRef.setValue(dict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else {
            completion(.failure(NSError(domain: "EncodingError", code: 0)))
        }
    } catch {
        completion(.failure(error))
    }
}


func observeEventsRDB(onChange: @escaping ([Event]) -> Void) {
    let ref = Database.database().reference().child("events")
    
    ref.observe(.value) { snapshot in
        var events: [Event] = []
        for child in snapshot.children {
            if let snap = child as? DataSnapshot,
               let dict = snap.value as? [String: Any] {
                do {
                    let data = try JSONSerialization.data(withJSONObject: dict)
                    var event = try JSONDecoder().decode(Event.self, from: data)
                    event.id = snap.key
                    events.append(event)
                } catch {
                    print("Error decoding: \(error)")
                }
            }
        }
        onChange(events)
    }
}

