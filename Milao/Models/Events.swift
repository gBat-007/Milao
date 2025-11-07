//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import SwiftUI
import Foundation
import MapKit
import FirebaseDatabase
import UIKit
import CoreLocation
import AlarmKit

struct Event: Identifiable, Codable, Hashable, Equatable {
    var id: String //THIS IS THE INVITE CODE
    var title: String
    var emoji: String
    var members: [Member]
    var chats: [Chat]
    var places: [Place]
    var eventDate: Date
    var bgColor1: CodableColor
    var bgColor2: CodableColor
    
    var ownerID: String //Will be a UID this time
    
    var membersNum: Int {
        return members.count
    }
    
    var placesNum: Int {
        return places.count
    }
    
    // Computed convenience
    var colorGradient: LinearGradient {
        LinearGradient(
            colors: [bgColor1.color, bgColor2.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Initializers

    // Default new event initializer
    init(
        title: String,
        emoji: String? = nil,
        members: [Member],
        primaryColor: Color,
        secondaryColor: Color,
        eventDate: Date,
        inviteCode: String
    ) {
        self.id = inviteCode
        self.title = title
        self.emoji = emoji ?? "🎉"
        self.members = members
        self.chats = [Chat(title: "General", emoji: "💬", messages: [Message(text: "Welcome to the general chat.", isSentByMemberName: "Admin")])]
        self.places = []
        self.eventDate = eventDate
        self.bgColor1 = CodableColor(color: primaryColor)
        self.bgColor2 = CodableColor(color: secondaryColor)
        self.ownerID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    }

    // Firebase decoding initializer
    init(
        id: String,
        title: String,
        emoji: String,
        members: [Member],
        chats: [Chat],
        places: [Place],
//        plan: Plan,
        eventDate: Date,
        bgColor1: CodableColor,
        bgColor2: CodableColor,
        inviteCode: String,
        ownerID: String
    ) {
        self.id = inviteCode
        self.title = title
        self.emoji = emoji
        self.members = members
        self.chats = chats
        self.places = places
        self.eventDate = eventDate
        self.bgColor1 = bgColor1
        self.bgColor2 = bgColor2
        self.ownerID = ownerID
    }

    // MARK: - Codable customization to default missing members to []
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case emoji
        case members
        case chats
        case places
        case eventDate
        case bgColor1
        case bgColor2
        case ownerID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id in DB is the invite code key; we still decode if present, but it will be overwritten by caller
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""

        self.title = try container.decode(String.self, forKey: .title)
        self.emoji = try container.decode(String.self, forKey: .emoji)

        // Default missing members to []
        self.members = try container.decodeIfPresent([Member].self, forKey: .members) ?? []

        // Leave chats/places as-is (synthesized behavior); they must exist in your data
        self.chats = try container.decode([Chat].self, forKey: .chats)
        self.places = try container.decode([Place].self, forKey: .places)

        self.eventDate = try container.decode(Date.self, forKey: .eventDate)
        self.bgColor1 = try container.decode(CodableColor.self, forKey: .bgColor1)
        self.bgColor2 = try container.decode(CodableColor.self, forKey: .bgColor2)
        self.ownerID = try container.decode(String.self, forKey: .ownerID)
    }

    // We can rely on synthesized encode(to:) since CodingKeys is defined and matches properties.
    // No custom encode needed.

    // MARK: - Static Helpers

    static func generateInviteCode(length: Int = 6) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
}


extension Event {
    func deleteFromDatabase(completion: ((Result<Void, Error>) -> Void)? = nil) {
            let ref = Database.database().reference().child("events").child(self.id)
            ref.removeValue { error, _ in
                if let error = error {
                    completion?(.failure(error))
                } else {
                    completion?(.success(()))
                }
            }
        }
        func saveToDatabase(completion: ((Result<Void, Error>) -> Void)? = nil) {
            var eventToSave = self

            // Inject placeholders for empty arrays
            if eventToSave.places.isEmpty {
                eventToSave.places = [
                    Place(id: "placeholder", name: "placeholder", descriptionAI: "placeholder", emoji: "📍", location: Location(name: "placeholder", coordinate: Coordinate(latitude: 0.0, longitude: 0.0))
)
                ]
            }
            if eventToSave.members.isEmpty {
                eventToSave.members = [
                    Member(id: "placeholder", name: "placeholder", locationPlaceID: "0.0,0.0", profilePhotoURL: "placeholder", eventIDs: ["placeholder"])
                ]
            }
//            
//            let ref = Database.database().reference().child("events").child(eventToSave.id)
//            let encoder = JSONEncoder()
//            encoder.dateEncodingStrategy = .iso8601
//
//            do {
//                let data = try encoder.encode(eventToSave)
//                guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//                    completion?(.failure(NSError(domain: "EncodingError", code: 0)))
//                    return
//                }
//
//                // Fix color component types (ensure all components are Doubles)
//                func fixColorComponentTypes(in colorDict: inout [String: Any]) {
//                    for key in ["red", "green", "blue", "alpha"] {
//                        if let str = colorDict[key] as? String, let dbl = Double(str) {
//                            colorDict[key] = dbl
//                        }
//                    }
//                }
//
//                if var bgColor1 = dict["bgColor1"] as? [String: Any] {
//                    fixColorComponentTypes(in: &bgColor1)
//                    dict["bgColor1"] = bgColor1
//                }
//
//                if var bgColor2 = dict["bgColor2"] as? [String: Any] {
//                    fixColorComponentTypes(in: &bgColor2)
//                    dict["bgColor2"] = bgColor2
//                }
//
//                // Save updated data to Firebase
//                ref.setValue(dict) { error, _ in
//                    if let error = error {
//                        completion?(.failure(error))
//                    } else {
//                        completion?(.success(()))
//                    }
//                }
//
//            } catch {
//                completion?(.failure(error))
//            }
        }
    }


let myEvents: [Event] = []

extension Event {
    var asWidgetEvent: WidgetEvent {
        WidgetEvent(
            id: self.id,
            title: self.title,
            emoji: self.emoji,
            eventDate: self.eventDate,
            memberCount: self.membersNum,
            placesNum: self.placesNum,
            bgColor1: self.bgColor1,
            bgColor2: self.bgColor2
        )
    }
    
    func newWidgetEvent(event: Event) -> WidgetEvent {
            WidgetEvent(
                id: event.id,
                title: event.title,
                emoji: event.emoji,
                eventDate: event.eventDate,
                memberCount: event.membersNum,
                placesNum: event.placesNum,
                bgColor1: event.bgColor1,
                bgColor2: event.bgColor2
            )
        }
}

