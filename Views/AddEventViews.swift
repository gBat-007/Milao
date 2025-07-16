import Foundation
import SwiftUI

class LocalEventStore {
    private let key = "local_events"

    func save(event: Event) {
        var events = fetchEvents()
        events.append(event)
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func fetchEvents() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let events = try? JSONDecoder().decode([Event].self, from: data) else {
            return []
        }
        return events
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}


struct AddEventMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var createMode = false
    @State private var joinMode = false

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
                    dismiss()
                }
            }
            .sheet(isPresented: $joinMode) {
                JoinEventView()
            }
        }
    }
}

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var primaryColor = Color.accentColor
    @State private var secondaryColor = Color.gray
    @State private var emoji = ""
    @State private var selectedDateTime: Date = Date()
    @State private var inviteCode = Event.generateInviteCode()
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let repo = EventRepository()
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
                    EmojiTextField(text: $emoji)
                        .frame(width: 60, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
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
        let event = Event(
            id: UUID().uuidString,
            title: title,
            emoji: emoji,
            members: [],
            chats: [],
            places: [],
            plans: [],
            eventDate: selectedDateTime,
            bgColor1: CodableColor(color: primaryColor),
            bgColor2: CodableColor(color: secondaryColor),
            inviteCode: inviteCode
        )
        
        // Save locally no matter what
        LocalEventStore().save(event: event)
        
        // Then try cloud, if it fails, show a message
        repo.createEvent(event) { result in
            isSaving = false
            switch result {
            case .success:
                onSuccess(event)
                dismiss()
            case .failure(let error):
                errorMessage = "Saved locally. Could not upload: \(error.localizedDescription)"
                onSuccess(event) // Still proceed as if it's saved
                dismiss()
            }
        }
    }
}

struct JoinEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isJoining = false
    private let repo = EventRepository()
    
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
        repo.joinEvent(inviteCode: code) { result in
            isJoining = false
            switch result {
            case .success(let event):
                // Add local state or navigation to that event
                dismiss()
            case .failure:
                errorMessage = "No event found for this code."
            }
        }
    }
}
