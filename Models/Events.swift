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
import FirebaseDatabase


struct Event: Identifiable, Codable {
    var id: String?
    var title: String
    var emoji: String
    var members: [Member]
    var chats: [Chat]
    var places: [Place]
    var plan: Plan
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
        self.id = UUID().uuidString
        self.title = title
        self.emoji = emoji ?? "x" // will later do AI stuff with this
        self.bgColor1 = CodableColor(color: primaryColor)
        self.bgColor2 = CodableColor(color: secondaryColor)
        self.inviteCode = Event.generateInviteCode()
        self.members = []
        self.places = []
        self.plan = Plan(locations: [])
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
        plan: Plan,
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
        self.plan = plan
        self.eventDate = eventDate
        self.bgColor1 = bgColor1
        self.bgColor2 = bgColor2
        self.inviteCode = inviteCode
    }
}

extension Event {
    func saveToDatabase() {
        guard let eventId = self.id else { return }
        let ref = Database.database().reference().child("events").child(eventId)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // or your preferred date format

        do {
            let data = try encoder.encode(self)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let dict = json {
                ref.setValue(dict)
            }
        } catch {
            print("Error encoding or saving event: \(error)")
        }
    }
}


let myEvents: [Event] = []
