//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import SwiftUI
import Foundation
import MapKit

struct Event: Identifiable, Codable {
    let id: UUID = UUID()
    var title: String
    var emoji: String
    var membersNum: Int
    var locationsNum: Int
    var members: [Member]
    var chats: [Chat]
    var location: [Location]
}

struct Coordinate: Hashable, Codable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Member: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var email: String
}

struct Location: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var coordinate: Coordinate
}

let myEvents: [Event] = [
    Event(title: "Birthday Bash", emoji: "🥳", membersNum: 15, locationsNum: 3, members: [Member(name: "Gaurav", email: "gayestalive@gmail.in")], chats: [Chat(title: "Birthday Bash", emoji: "🥳", membersNum: 15)], location: [Location(name: "x", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933))]),
    Event(title: "Alumni Hangout", emoji: "🎓", membersNum: 23, locationsNum: 1, members: [Member(name: "Gautam", email: "gayeralive@gmail.in"),Member(name: "Mahith", email: "lgbtqalive@gmail.in"),Member(name: "Saurish", email: "lesbianalive@gmail.in")], chats: [Chat(title: "Alumni Hangout", emoji: "🎓", membersNum: 23)], location: [Location(name: "y", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933)), Location(name: "yay", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933))]),
    Event(title: "Study Group", emoji: "📕", membersNum: 21, locationsNum: 4, members: [Member(name: "Gautam", email: "gayalive@gmail.in")], chats: [Chat(title: "Study Group", emoji: "📕", membersNum: 21)], location: [Location(name: "z", coordinate: Coordinate(latitude: -48.8767, longitude: -123.3933))])
]
