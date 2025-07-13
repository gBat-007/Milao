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
    @DocumentID var id: String? = UUID().uuidString
    var title: String
    var emoji: String
    var membersNum: Int
    var locationsNum: Int
    var members: [Member]
    var chats: [Chat]
    var places: [Place]
    var plans: [Plan]
    var bgColor1: CodableColor = CodableColor(color: .white)
}

struct Coordinate: Hashable, Codable, Equatable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var locationPlaceID: String
}


extension Member {
    func encodeToData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(from data: Data?) -> Member? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(Member.self, from: data)
    }

    var coordinate: CLLocationCoordinate2D? {
        let parts = locationPlaceID.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: parts[0], longitude: parts[1])
    }
}


struct Location: Identifiable, Codable, Equatable{
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var coordinate: Coordinate
}

struct Plan: Identifiable, Codable, Equatable{
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var locations: [Location]
}

@Generable
struct Place: Identifiable, Equatable, Codable{
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var descriptionAI: String
    var emoji: String
}

let myEvents: [Event] = [
    Event(title: "Birthday Bash", emoji: "🥳", membersNum: 15, locationsNum: 3,
          members: [],
          chats: [Chat(title: "Birthday Bash", emoji: "🥳", membersNum: 15)],
          places: [],
          plans: [Plan(name: "Plan 1", locations: [Location(name: "Point Nemo", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933)),Location(name: "Apple Park", coordinate: Coordinate(latitude: 37.3346, longitude: -122.0090))])]
         ),
    Event(title: "Alumni Hangout", emoji: "🎓", membersNum: 23, locationsNum: 1,
          members: [],
          chats: [Chat(title: "Alumni Hangout", emoji: "🎓", membersNum: 23)],
          places: [],
          plans: [Plan(name: "Plan 1", locations: [Location(name: "Point Nemo", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933)),Location(name: "Apple Park", coordinate: Coordinate(latitude: 37.3346, longitude: -122.0090))])]
         ),
    Event(title: "Study Group", emoji: "📕", membersNum: 21, locationsNum: 4,
          members: [],
          chats: [Chat(title: "Study Group", emoji: "📕", membersNum: 21)],
          places: [],
          plans: []
         )
]
