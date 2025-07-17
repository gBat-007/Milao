import SwiftUI
import UIKit

struct ChatsTab: View {
    @Binding var event: Event
    @Binding var presentAddChatSheet: Bool

    var body: some View {
        VStack {
            List(event.chats.indices, id: \.self) { index in
                let chat = event.chats[index]
                HStack {
                    Text(chat.emoji)
                        .font(.largeTitle)
                        .frame(width: 40)

                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("\(chat.membersNum) member\(chat.membersNum == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddChatSheet) {
            AddChatView { newChat in
                event.chats.append(newChat)
            }
            .presentationDetents([.medium])
        }
    }
}

struct AddChatView: View {
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var emoji = "💬"
    @State private var membersNum = 1

    var onAdd: (Chat) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat Details")) {
                    TextField("Title", text: $title)
                    HStack{
                        Text("Emoji ")
                            .fontDesign(.rounded)
                        EmojiTextField(text: $emoji)
                            .frame(width: 60, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                    }
                    Stepper("Members: \(membersNum)", value: $membersNum, in: 1...100)
                }
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newChat = Chat(title: title, emoji: emoji, membersNum: membersNum)
                        onAdd(newChat)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || emoji.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
