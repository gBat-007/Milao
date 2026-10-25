import FirebaseDatabase
import FirebaseAuth
import Foundation
import UIKit

func saveEventRDB(_ event: Event, completion: @escaping (Result<Event, Error>) -> Void) {
    let ref = Database.database().reference()
    let id = event.id

    var eventToSave = event
    eventToSave.id = id
    if eventToSave.places.isEmpty {
        eventToSave.places = [
            Place(
                id: "placeholder",
                name: "placeholder",
                descriptionAI: "placeholder",
                emoji: "📍",
                location: Location(
                    name: "placeholder",
                    coordinate: Coordinate(latitude: 0.0, longitude: 0.0)
                )
            )
        ]
    }
    if eventToSave.chats.isEmpty {
        eventToSave.chats = [
            Chat(
                title: "General",
                emoji: "💬",
                messages: [Message(text: "Welcome to the general chat.", isSentByMemberName: "Admin", timestamp: eventToSave.eventDate)]
            )
        ]
    }

    do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(eventToSave)
        guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(.failure(NSError(domain: "EncodingError", code: 0)))
            return
        }

        let memberIDs = eventToSave.members.map { $0.id }
        dict["memberIDs"] = memberIDs
        dict.removeValue(forKey: "members")

        func fixColorComponentTypes(in colorDict: inout [String: Any]) {
            for key in ["red", "green", "blue", "alpha"] {
                if let str = colorDict[key] as? String, let dbl = Double(str) {
                    colorDict[key] = dbl
                }
            }
        }

        if var bgColor1 = dict["bgColor1"] as? [String: Any] {
            fixColorComponentTypes(in: &bgColor1)
            dict["bgColor1"] = bgColor1
        }
        if var bgColor2 = dict["bgColor2"] as? [String: Any] {
            fixColorComponentTypes(in: &bgColor2)
            dict["bgColor2"] = bgColor2
        }

        ref.child("events").child(id).setValue(dict) { error, _ in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(event))
            }
        }

        for memberId in memberIDs {
            let eventIDsRef = ref.child("users").child(memberId).child("eventIDs")
            eventIDsRef.getData { error, snapshot in
                guard error == nil else { return }
                var ids = snapshot?.value as? [String] ?? []
                if !ids.contains(id) {
                    ids.append(id)
                    eventIDsRef.setValue(ids)
                }
            }
        }
    } catch {
        completion(.failure(error))
    }
}

private func stringIDs(from value: Any?) -> [String] {
    if let ids = value as? [String] {
        return ids
    }
    if let ids = value as? [Any] {
        return ids.compactMap { $0 as? String }
    }
    if let members = value as? [String: Any] {
        // Android currently writes member IDs as a list, while earlier records
        // may contain a UID-keyed map. Accept both Realtime Database shapes.
        return members.keys.sorted()
    }
    return []
}

private func makeEventDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        if let seconds = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: seconds / 1000)
        }
        let value = try container.decode(String.self)
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        if let date = standard.date(from: value) { return date }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported event date: \(value)"
        )
    }
    return decoder
}

private func events(from snapshot: DataSnapshot) -> [Event] {
        // Never block the visible event list on reading the entire users tree.
        // On Android-created events, event visibility comes from memberIDs, and
        // user profiles are not required to decode or display the event card.
        guard let userID = Auth.auth().currentUser?.uid else { return [] }

        var events: [Event] = []
        for child in snapshot.children {
            guard let child = child as? DataSnapshot,
                  var dict = child.value as? [String: Any] else { continue }

            var memberIDs = stringIDs(from: dict["memberIDs"])
            if memberIDs.isEmpty {
                memberIDs = stringIDs(from: dict["members"])
            }
            guard memberIDs.contains(userID) else { continue }

            // Android writes its membership map as compatibility data. Remove it
            // before Codable sees Event.members, which is an array on iOS.
            dict.removeValue(forKey: "memberIDs")
            dict.removeValue(forKey: "members")
            dict["id"] = child.key
            dict["chats"] = dict["chats"] ?? []
            dict["places"] = dict["places"] ?? []
            dict["emoji"] = dict["emoji"] ?? "🎉"
            dict["ownerID"] = dict["ownerID"] ?? ""

            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                var event = try makeEventDecoder().decode(Event.self, from: data)
                event.id = child.key
                // Keep member counts and identity available in the list immediately.
                event.members = memberIDs.map {
                    Member(id: $0, name: "", locationPlaceID: "", eventIDs: [])
                }
                event.places.removeAll { $0.id == "placeholder" }
                events.append(event)
            } catch {
                print("❌ Could not decode event \(child.key) from Realtime Database: \(error)")
            }
        }

        events.sort { $0.eventDate > $1.eventDate }
        return events
}

@discardableResult
func observeEventsRDB(onChange: @escaping ([Event]) -> Void) -> DatabaseHandle {
    let eventsRef = Database.database().reference().child("events")
    return eventsRef.observe(.value, with: { snapshot in
        let events = events(from: snapshot)
        DispatchQueue.main.async {
            print("🔄 Realtime Database returned \(events.count) events for current user")
            onChange(events)
        }
    }, withCancel: { error in
        print("❌ Realtime Database event listener failed: \(error.localizedDescription)")
        DispatchQueue.main.async { onChange([]) }
    })
}

func refreshEventsRDB(completion: @escaping ([Event]) -> Void) {
    Database.database().reference().child("events").getData { error, snapshot in
        if let error {
            print("❌ Realtime Database refresh failed: \(error.localizedDescription)")
            DispatchQueue.main.async { completion([]) }
            return
        }
        let events = snapshot.map(events(from:)) ?? []
        DispatchQueue.main.async { completion(events) }
    }
}
