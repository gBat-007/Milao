//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import Foundation

struct Event: Identifiable, Codable {
    let id: UUID = UUID()
    var title: String
    var emoji: String
    var membersNum: Int
    var locationsNum: Int
    var members: [Member]
    var location: [Location]
}

struct Member: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var email: String
}

struct Location: Identifiable, Codable {
    let id: UUID = UUID()
    var lat: String
    var lon: String
    var name: String
}

let myEvents: [Event] = [
    Event(title: "Birthday Bash", emoji: "🥳", membersNum: 15, locationsNum: 3, members: [Member(name: "Gaurav", email: "gayestalive@gmail.in")], location: [Location]),
    Event(title: "Alumni Hangout", emoji: "🎓", membersNum: 23, locationsNum: 1, members: <#[Member]#>, location: <#[Location]#>),
    Event(title: "Study Group", emoji: "📕", membersNum: 21, locationsNum: 4, members: <#[Member]#>, location: <#[Location]#>)
]
