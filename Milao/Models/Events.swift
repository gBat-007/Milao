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

struct Event: Identifiable, Codable, Hashable, Equatable {
    var id: String
    var title: String
    var emoji: String
    var members: [Member]
    var chats: [Chat]
    var places: [Place]
    var plan: Plan
    var eventDate: Date
    var bgColor1: CodableColor
    var bgColor2: CodableColor
    var inviteCode: String
    var ownerID: String
    
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
        self.id = UUID().uuidString
        self.title = title
        self.emoji = emoji ?? "🎉"
        self.members = members
        self.chats = [Chat(title: "General", emoji: "💬", messages: [Message(text: "Welcome to the general chat.", isSentByMemberName: "Admin")])]
        self.places = []
        self.plan = Plan(locations: [])
        self.eventDate = eventDate
        self.bgColor1 = CodableColor(color: primaryColor)
        self.bgColor2 = CodableColor(color: secondaryColor)
        self.inviteCode = inviteCode
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
        plan: Plan,
        eventDate: Date,
        bgColor1: CodableColor,
        bgColor2: CodableColor,
        inviteCode: String,
        ownerID: String
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.members = members
        self.chats = chats
        self.places = places
        self.plan = plan
        self.eventDate = eventDate
        self.bgColor1 = bgColor1
        self.bgColor2 = bgColor2
        self.inviteCode = inviteCode
        self.ownerID = ownerID
    }

    // MARK: - Static Helpers

    static func generateInviteCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
}


extension Event {
        func saveToDatabase(completion: ((Result<Void, Error>) -> Void)? = nil) {
            var eventToSave = self

            // Inject placeholders for empty arrays
            if eventToSave.places.isEmpty {
                eventToSave.places = [
                    Place(id: "placeholder", name: "placeholder", descriptionAI: "placeholder", emoji: "📍")
                ]
            }
            if eventToSave.members.isEmpty {
                eventToSave.members = [
                    Member(id: "placeholder", name: "placeholder", locationPlaceID: "placeholder")
                ]
            }
            if eventToSave.plan.locations.isEmpty {
                eventToSave.plan.locations = [
                    Location(name: "placeholder", coordinate: Coordinate(latitude: 0.0, longitude: 0.0), ofPlace: Place(id: "placeholder", name: "placeholder", descriptionAI: "placeholder", emoji: "📍"))
                ]
            }

            let ref = Database.database().reference().child("events").child(eventToSave.id)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            do {
                let data = try encoder.encode(eventToSave)
                guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion?(.failure(NSError(domain: "EncodingError", code: 0)))
                    return
                }

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

                // Save updated data to Firebase
                ref.setValue(dict) { error, _ in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(()))
                    }
                }

            } catch {
                completion?(.failure(error))
            }
        }
    }


let myEvents: [Event] = []


struct DeviceManager {
    static var deviceID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    }
}

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
}

