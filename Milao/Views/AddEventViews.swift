import Foundation
import SwiftUI
import FirebaseDatabase



struct AddEventMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var createMode = false
    @State private var joinMode = false

    var onEventCreatedOrJoined: (Event) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Create New Event") { createMode = true }
                    Button("Join with Code") { joinMode = true }
                }
            }
            .navigationTitle("Add Event")
            .sheet(isPresented: $createMode) {
                CreateEventView { newEvent in
                    onEventCreatedOrJoined(newEvent)
                    dismiss()
                }
            }
            .sheet(isPresented: $joinMode) {
                JoinEventView { joinedEvent in
                    onEventCreatedOrJoined(joinedEvent)
                    dismiss()
                }
            }
        }
    }
}


struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var primaryColor = Color.accentColor
    @State private var secondaryColor = Color.gray
    @State private var emoji = "😃"
    @State private var selectedDateTime: Date = Date()
    @State private var inviteCode = Event.generateInviteCode()
    @State private var isSaving = false
    @State private var errorMessage: String?
    private var dateRange: ClosedRange<Date> {
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        return now...oneYearFromNow
    }
    
    var onSuccess: (Event) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Event Name", text: $title)
                
                ColorPicker("Primary Color", selection: $primaryColor)
                ColorPicker("Secondary Color", selection: $secondaryColor)
                
                HStack{
                    Text("Emoji ")
                        .fontDesign(.rounded)
                    EmojiKeyboardButton(emoji: $emoji)
                        .frame(width: 50, height: 50)
                        .overlay(RoundedRectangle(cornerRadius: 45).stroke(Color.gray.opacity(0.4)).blur(radius: 20.0))
                }
                
                DatePicker("Event Date & Start Time", selection: $selectedDateTime, in: dateRange, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact) // or .compact / .wheel
                .padding()
                
                HStack {
                    Text("Invite Code:")
                    Spacer()
                    InviteCodeView(inviteCode: inviteCode)
                }
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Create Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        saveEvent()
                    }
                    .disabled(isSaving || title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    private func saveEvent() {
        isSaving = true
        
        guard let memberData = UserDefaults.standard.data(forKey: "memberData"),
              let currentMember = try? JSONDecoder().decode(Member.self, from: memberData) else {
            errorMessage = "Could not load current member."
            isSaving = false
            return
        }
        
        let event = Event(
            title: title,
            emoji: emoji,
            members: [currentMember],
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            eventDate: selectedDateTime,
            inviteCode: inviteCode
        )
        
        saveEventRDB(event) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    onSuccess(event) // <- this ensures the event shows up in the list
                case .failure(let error):
                    print("Save failed: \(error)")
                    // show error toast
                }
            }
        }
    }
}
struct JoinEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isJoining = false

    var onSuccess: (Event) -> Void

    var body: some View {
        Form {
            TextField("Invite Code", text: $code)
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            Button(isJoining ? "Joining..." : "Join") {
                joinEvent()
            }
            .disabled(code.count != 6 || isJoining)
        }
        .navigationTitle("Join Event")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    private func joinEvent() {
        isJoining = true
        errorMessage = nil

        let ref = Database.database().reference().child("events")

        ref.observeSingleEvent(of: .value) { snapshot in
            var matchedSnapshot: DataSnapshot?

            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let dict = snap.value as? [String: Any],
                   let inviteCodeInDB = dict["inviteCode"] as? String,
                   inviteCodeInDB.uppercased() == code.uppercased() {
                    matchedSnapshot = snap
                    break
                }
            }

            guard let snap = matchedSnapshot,
                  let dict = snap.value as? [String: Any] else {
                isJoining = false
                errorMessage = "No event found with that code."
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
                var event = try jsonDecoder.decode(Event.self, from: data)
                event.id = snap.key

                if let memberData = UserDefaults.standard.data(forKey: "memberData"),
                   let currentMember = try? JSONDecoder().decode(Member.self, from: memberData) {

                    // Only append if not already a member
                    if !event.members.contains(where: { $0.id == currentMember.id }) {
                        event.members.append(currentMember)

                        // Save updated event to Firebase
                        let eventRef = ref.child(event.id)
                        let encodedData = try JSONEncoder().encode(event)
                        let dict = try JSONSerialization.jsonObject(with: encodedData) as? [String: Any] ?? [:]

                        eventRef.setValue(dict) { error, _ in
                            isJoining = false
                            if let error = error {
                                errorMessage = "Joined locally, but couldn't sync: \(error.localizedDescription)"
                            } else {
                                errorMessage = nil
                            }
                            onSuccess(event)
                        }
                    } else {
                        // Already a member
                        isJoining = false
                        errorMessage = nil
                        onSuccess(event)
                    }

                } else {
                    isJoining = false
                    errorMessage = "Could not load your member profile."
                }

            } catch {
                isJoining = false
                errorMessage = "Could not decode event data."
            }

        } withCancel: { error in
            isJoining = false
            errorMessage = "Failed to fetch events: \(error.localizedDescription)"
        }
    }

}







//class LocalEventStore {
//    private let key = "local_events"
//
//    func save(event: Event) {
//        var events = fetchEvents()
//        events.append(event)
//        if let data = try? JSONEncoder().encode(events) {
//            UserDefaults.standard.set(data, forKey: key)
//        }
//    }
//
//    func fetchEvents() -> [Event] {
//        guard let data = UserDefaults.standard.data(forKey: key),
//              let events = try? JSONDecoder().decode([Event].self, from: data) else {
//            return []
//        }
//        return events
//    }
//
//    func save(events: [Event]) {
//        if let data = try? JSONEncoder().encode(events) {
//            UserDefaults.standard.set(data, forKey: key)
//        }
//    }
//
//    func clear() {
//        UserDefaults.standard.removeObject(forKey: key)
//    }
//}
