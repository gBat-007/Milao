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
}

let myEvents: [Event] = [
    Event(title: "Birthday Bash", emoji: "d", membersNum: 15, locationsNum: 3),
    Event(title: "Alumni Hangout", emoji: "e", membersNum: 23, locationsNum: 1),
    Event(title: "Study Group", emoji: "f", membersNum: 21, locationsNum: 4)
]
