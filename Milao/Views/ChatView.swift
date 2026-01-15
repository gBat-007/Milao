import SwiftUI
import FirebaseDatabase

struct ChatsView: View {
    let eventId: String
    let chatIndex: Int
    @Binding var chat: Chat
    var thisMember: String
    @Binding var newMessage: String

    @State private var messagesListenerHandle: DatabaseHandle?

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chat.messages) { message in
                            VStack(alignment: message.isSentByMemberName == thisMember ? .trailing : .leading, spacing: 2) {
                                Text("\(message.isSentByMemberName) at \(message.isSentByMemberName == "Admin" ? "the dawn of time" : message.timestamp.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                HStack {
                                    if message.isSentByMemberName == thisMember {
                                        Spacer()
                                        Text(message.text)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(14)
                                    } else {
                                        Text(message.text)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.orange.opacity(0.9))
                                            .foregroundColor(.black)
                                            .cornerRadius(14)
                                        Spacer()
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = message.text
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                }
                                
                            }
                            .id(message.id)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: chat.messages.count) {
                    if let last = chat.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            Divider()
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
        }
        .navigationTitle(chat.title)
        .onAppear(perform: startMessagesListener)
        .onDisappear(perform: stopMessagesListener)
    }

    func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Add locally
        let newMsg = Message(text: trimmed, isSentByMemberName: thisMember, timestamp: Date.now)
        chat.messages.append(newMsg)
        newMessage = ""
        // Save to Firebase
        let ref = Database.database().reference()
        let messagesRef = ref.child("events").child(eventId).child("chats").child("\(chatIndex)").child("messages")
        let messageDict: [String: Any] = [
            "id": newMsg.id,
            "text": newMsg.text,
            "isSentByMemberName": newMsg.isSentByMemberName,
            "timestamp": newMsg.timestamp.ISO8601Format()
        ]
        messagesRef.child(newMsg.id).setValue(messageDict)
        NotificationCenter.default.post(name: .didSendMessage, object: nil)
    }

    private func startMessagesListener() {
        let ref = Database.database().reference()
        let messagesRef = ref.child("events").child(eventId).child("chats").child("\(chatIndex)").child("messages")
        messagesListenerHandle = messagesRef.observe(.value) { snapshot in
            var newMessages: [Message] = []
            for child in snapshot.children {
                guard
                    let snap = child as? DataSnapshot,
                    let dict = snap.value as? [String: Any],
                    let id = dict["id"] as? String,
                    let text = dict["text"] as? String,
                    let sender = dict["isSentByMemberName"] as? String,
                    let timestampString = dict["timestamp"] as? String
                else {
                    continue
                }
                let isoFormatter = ISO8601DateFormatter()
                let timestamp = isoFormatter.date(from: timestampString)
                let msg = Message(id: id, text: text, isSentByMemberName: sender, timestamp: timestamp ?? Date.now)
                newMessages.append(msg)
            }
            chat.messages = newMessages
        }
    }

    private func stopMessagesListener() {
        if let handle = messagesListenerHandle {
            let ref = Database.database().reference()
            let messagesRef = ref.child("events").child(eventId).child("chats").child("\(chatIndex)").child("messages")
            messagesRef.removeObserver(withHandle: handle)
        }
    }
}

extension Notification.Name {
    static let didSendMessage = Notification.Name("didSendMessage")
}
