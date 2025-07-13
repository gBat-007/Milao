//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var title: String
    var emoji: String
    var membersNum: Int
}

let myChats: [Chat] = [
    Chat(title: "Birthday Bash", emoji: "🥳", membersNum: 15),
    Chat(title: "Alumni Hangout", emoji: "🎓", membersNum: 23),
    Chat(title: "Study Group", emoji: "📕", membersNum: 21)
]
