import FirebaseDatabase
import Foundation
import UIKit

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dict = try JSONSerialization.jsonObject(with: data, options: [])
        guard let result = dict as? [String: Any] else {
            throw NSError(domain: "SerializationError", code: 0)
        }
        return result
    }
}

func convertToFirebaseDict<T: Encodable>(_ object: T) throws -> [String: Any] {
    let data = try JSONEncoder().encode(object)
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    
    guard let dict = jsonObject as? [String: Any] else {
        throw NSError(domain: "Milao", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
    }
    
    return dict
}

func saveEventRDB(_ event: Event, completion: @escaping (Result<Event, Error>) -> Void) {
    let ref = Database.database().reference()
    let id = event.id

    var eventToSave = event
    eventToSave.id = id

    // Inject placeholders for empty arrays
    if eventToSave.places.isEmpty {
        eventToSave.places = [
            Place(id: "placeholder", name: "placeholder", descriptionAI: "placeholder", emoji: "📍", location: Location(name: "placeholder", coordinate: Coordinate(latitude: 0.0, longitude: 0.0)))
        ]
    }
    if eventToSave.members.isEmpty {
        eventToSave.members = [
            Member(id: "placeholder", name: "placeholder", locationPlaceID: "placeholder")
        ]
    }
//    if eventToSave.plan.locations.isEmpty {
//        eventToSave.plan.locations = [
//            Location(name: "placeholder", coordinate: Coordinate(latitude: 0.0, longitude: 0.0), ofPlace: Place(id: "placeholder", name: "placeholder", descriptionAI: "placeholder", emoji: "📍"))
//        ]
//    }
    if eventToSave.chats.isEmpty {
        eventToSave.chats = [Chat(title: "General", emoji: "💬", messages: [Message(text: "Welcome to the general chat.", isSentByMemberName: "Admin")])]
    }
    do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(eventToSave)

        guard var dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return completion(.failure(NSError(domain: "EncodingError", code: 0)))
        }

        // 🔧 Manually convert color fields to use Doubles if needed
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

        // ✅ Upload to Firebase
        ref.child("events").child(id).setValue(dict) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(event))
            }
        }

    } catch {
        completion(.failure(error))
    }
}



func observeEventsRDB(onChange: @escaping ([Event]) -> Void) {
    let ref = Database.database().reference().child("events")
    guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
        print("❌ Could not get device ID.")
        onChange([])
        return
    }

    var currentMember: Member?
    if let data = UserDefaults.standard.data(forKey: "memberData"),
       let member = try? JSONDecoder().decode(Member.self, from: data) {
        currentMember = member
    }

    ref.observe(.value, with: { snapshot in
        var events: [Event] = []

        for child in snapshot.children {
            guard let snap = child as? DataSnapshot,
                  let dict = snap.value as? [String: Any] else {
                continue
            }

            do {
                print("📦 Raw event dict: \(dict)")
                let data = try JSONSerialization.data(withJSONObject: dict)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
                var event = try jsonDecoder.decode(Event.self, from: data)
                event.id = snap.key

                // Remove placeholder entries
                event.members.removeAll { $0.id == "placeholder" }
                event.places.removeAll { $0.id == "placeholder" }
//                event.plan.locations.removeAll { $0.name == "placeholder" }

                let isOwnedByUser = event.ownerID == deviceId
                let isUserInMembers = currentMember.map { member in
                    event.members.contains(where: { $0.id == member.id })
                } ?? false

                if isOwnedByUser || isUserInMembers {
                    events.append(event)
                }

            } catch let decodingError as DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key '\(key.stringValue)' – \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for \(type) – \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for \(type) – \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted – \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error: \(decodingError)")
                }
            } catch {
                print("❌ General decoding error: \(error.localizedDescription)")
            }
        }

        print("🔄 Events updated: \(events.count) events received from Firebase.")
        onChange(events)
    })
}
