import SwiftUI
import UIKit

struct ChatsTab: View {
    @Binding var chats: [Chat]
    @Binding var presentAddChatSheet: Bool

    var body: some View {
        VStack {
            List(chats.indices, id: \.self) { index in
                let chat = chats[index]
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
                chats.append(newChat)
            }
            .presentationDetents([.medium])
        }
    }
}

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(_ parent: EmojiTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Filter to just first emoji-like character
            if let first = textField.text?.first {
                parent.text = String(first)
                textField.text = parent.text
            } else {
                parent.text = ""
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.textAlignment = .center
        textField.keyboardType = .default // Let the user choose emoji keyboard
        textField.returnKeyType = .done
        textField.tintColor = .clear
        textField.text = text
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
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
                    EmojiTextField(text: $emoji)
                        .frame(width: 60, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
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
