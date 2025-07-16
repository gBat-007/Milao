//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import SwiftUI
import Foundation
import MapKit
import FoundationModels
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var emoji: String
    var members: [Member]
    var chats: [Chat]
    var places: [Place]
    var plans: [Plan]
    var eventDate: Date
    var membersNum: Int {
        return members.count
    }
    var placesNum: Int {
        return places.count
    }
    var bgColor1: CodableColor = CodableColor(color: .white)
    var bgColor2: CodableColor = CodableColor(color: .white)
    var inviteCode: String

    static func generateInviteCode() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyz")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    /// Creates a new `Event` with empty initial arrays.
    init(title: String, emoji: String?, primaryColor: Color, secondaryColor: Color, eventDate: Date) {
        self.title = title
        self.emoji = emoji ?? "x" // will later do AI stuff with this
        self.bgColor1 = CodableColor(color: primaryColor)
        self.bgColor2 = CodableColor(color: secondaryColor)
        self.inviteCode = Event.generateInviteCode()
        self.members = []
        self.places = []
        self.plans = []
        self.chats = []
        self.eventDate = eventDate
    }

    /// Creates an `Event` with all provided values, to be used in decoding & sharing events.
    init(
        id: String?,
        title: String,
        emoji: String,
        members: [Member],
        chats: [Chat],
        places: [Place],
        plans: [Plan],
        eventDate: Date,
        bgColor1: CodableColor,
        bgColor2: CodableColor,
        inviteCode: String
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.members = members
        self.chats = chats
        self.places = places
        self.plans = plans
        self.eventDate = eventDate
        self.bgColor1 = bgColor1
        self.bgColor2 = bgColor2
        self.inviteCode = inviteCode
    }
}

struct Coordinate: Hashable, Codable, Equatable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


struct Location: Identifiable, Codable, Equatable{
    @DocumentID var id: String?
    var name: String
    var coordinate: Coordinate
}

struct Plan: Identifiable, Codable, Equatable{
    @DocumentID var id: String?
    var name: String
    var locations: [Location]
}

@Generable
struct Place: Identifiable, Equatable, Codable{
    @DocumentID var id: String?
    var name: String
    var descriptionAI: String
    var emoji: String
}

let myEvents: [Event] = [
//    Event(title: "Birthday Bash", emoji: "🥳", membersNum: 15, locationsNum: 3,
//          members: [],
//          chats: [Chat(title: "Birthday Bash", emoji: "🥳", membersNum: 15)],
//          places: [],
//          plans: [Plan(name: "Plan 1", locations: [Location(name: "Point Nemo", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933)),Location(name: "Apple Park", coordinate: Coordinate(latitude: 37.3346, longitude: -122.0090))])]
//         ),
//    Event(title: "Alumni Hangout", emoji: "🎓", membersNum: 23, locationsNum: 1,
//          members: [],
//          chats: [Chat(title: "Alumni Hangout", emoji: "🎓", membersNum: 23)],
//          places: [],
//          plans: [Plan(name: "Plan 1", locations: [Location(name: "Point Nemo", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933)),Location(name: "Apple Park", coordinate: Coordinate(latitude: 37.3346, longitude: -122.0090))])]
//         ),
//    Event(title: "Study Group", emoji: "📕", membersNum: 21, locationsNum: 4,
//          members: [],
//          chats: [Chat(title: "Study Group", emoji: "📕", membersNum: 21)],
//          places: [],
//          plans: []
//         )
]
