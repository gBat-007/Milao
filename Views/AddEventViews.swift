import Foundation
import SwiftUI

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
    @State private var inviteCode = Event.generateInviteCode()
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let repo = EventRepository()

    var onSuccess: (Event) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Event Name", text: $title)
                
                ColorPicker("Primary Color", selection: $primaryColor)
                ColorPicker("Secondary Color", selection: $secondaryColor)
                
                TextField("Emoji (optional)", text: $emoji)
                
                HStack {
                    Text("Invite Code:")
                    Spacer()
                    Text(inviteCode)
                        .font(.system(.body, design: .monospaced))
                        .bold()
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
            id: "",
            title: title,
            emoji: emoji,
            members: [],
            chats: [],
            places: [],
            plans: [],
            bgColor1: CodableColor(color: primaryColor),
            bgColor2: CodableColor(color: secondaryColor),
            inviteCode: inviteCode
        )

        repo.createEvent(event) { result in
            isSaving = false
            switch result {
            case .success:
                onSuccess(event)
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
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
