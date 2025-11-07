import FirebaseDatabase
import Foundation
import UIKit

func saveEventRDB(_ event: Event, completion: @escaping (Result<Event, Error>) -> Void) {
    let ref = Database.database().reference()
    let id = event.id

    var eventToSave = event
    eventToSave.id = id
    // Inject placeholders for empty arrays (keep for places/chats only)
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
                messages: [Message(text: "Welcome to the general chat.", isSentByMemberName: "Admin")]
            )
        ]
    }

    do {
        // Encode as before to leverage Codable for everything except members
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(eventToSave)

        guard var dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return completion(.failure(NSError(domain: "EncodingError", code: 0)))
        }

        // Replace members with memberIDs for normalization
        let memberIDs = eventToSave.members.map { $0.id }
        dict["memberIDs"] = memberIDs
        dict.removeValue(forKey: "members")

        // Fix color component types (ensure all components are Doubles)
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

        // Upload to Firebase
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
    let rootRef = Database.database().reference()
    let eventsRef = rootRef.child("events")
    let usersRef = rootRef.child("users")

    let userid = UserDefaults.standard.string(forKey: "userID")
    
    // Observe all events
    eventsRef.observe(.value, with: { snapshot in
        // First, collect raw event dictionaries keyed by eventId
        var eventDictsByKey: [(key: String, value: [String: Any])] = []

        for child in snapshot.children {
            guard let snap = child as? DataSnapshot,
                  let dict = snap.value as? [String: Any] else {
                continue
            }
            eventDictsByKey.append((key: snap.key, value: dict))
        }

        if eventDictsByKey.isEmpty {
            print("🔄 Events updated: 0 events received from Firebase.")
            onChange([])
            return
        }

        // Collect all member IDs across all events
        var allMemberIDs = Set<String>()
        for (_, dict) in eventDictsByKey {
            if let ids = dict["memberIDs"] as? [String] {
                allMemberIDs.formUnion(ids)
            }
        }

        // Fetch users once to hydrate members
        usersRef.observeSingleEvent(of: .value, with:
        { (usersSnapshot: DataSnapshot) in
            var usersLookup: [String: [String: Any]] = [:]
            if let usersDict = usersSnapshot.value as? [String: Any] {
                for (uid, value) in usersDict {
                    if let v = value as? [String: Any] {
                        usersLookup[uid] = v
                    }
                }
            }

            var events: [Event] = []

            for (eventKey, dict) in eventDictsByKey {
                do {
                    // Prepare a mutable dict for decoding Event fields (without members)
                    var eventDecodingDict = dict

                    // Extract member IDs (preferred normalized path)
                    let memberIDs: [String]
                    if let ids = dict["memberIDs"] as? [String] {
                        memberIDs = ids
                    } else {
                        memberIDs = []
                    }

                    eventDecodingDict.removeValue(forKey: "memberIDs")

                    // Decode other event fields
                    let data = try JSONSerialization.data(withJSONObject: eventDecodingDict)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
                    var event = try jsonDecoder.decode(Event.self, from: data)
                    event.id = eventKey

                    // Hydrate members from usersLookup via Member.init(dictionary:)
                    let hydratedMembers: [Member] = memberIDs.compactMap { uid in
                        guard let uDict = usersLookup[uid] else { return nil }
                        return Member(dictionary: uDict)
                    }
                    
                    event.members = hydratedMembers

                    // Remove any placeholder entries we still might have for places
                    event.places.removeAll { $0.id == "placeholder" }

                    // Ownership/membership filter (same as before)
                    
//                    let isOwnedByUser = event.ownerID == deviceId
                    let isUserInMembers = event.members.contains(where: {userid == $0.id })

                    if /*isOwnedByUser ||*/ isUserInMembers {
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

            print("🔄 Events updated: \(events.count) events received from Firebase (hydrated).")
            onChange(events)
        })
    })
}
