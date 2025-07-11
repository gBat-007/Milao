//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import Foundation

struct Chat: Identifiable, Codable {
    let id: UUID = UUID()
    var title: String
    var emoji: String
    var membersNum: Int
    var locationsNum: Int
}

let myChats: [Chat] = [
    Chat(title: "Birthday Bash", emoji: "🥳", membersNum: 15, locationsNum: 3),
    Chat(title: "Alumni Hangout", emoji: "🎓", membersNum: 23, locationsNum: 1),
    Chat(title: "Study Group", emoji: "📕", membersNum: 21, locationsNum: 4)
]
