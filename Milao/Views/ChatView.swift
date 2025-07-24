import SwiftUI

struct ChatsView: View {
    @Binding var chat: Chat
    var thisMember: String
    @Binding var newMessage: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chat.messages) { message in
                            VStack(alignment: message.isSentByMemberName == thisMember ? .trailing : .leading, spacing: 2) {
                                // Name above the message
                                Text(message.isSentByMemberName)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)

                                // Message bubble
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

            // Input field and send button
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
    }
    
    func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        chat.messages.append(Message(text: trimmed, isSentByMemberName: thisMember))
        newMessage = ""

        // Save event manually via Notification or callback (recommended)
        NotificationCenter.default.post(name: .didSendMessage, object: nil)
    }
}

extension Notification.Name {
    static let didSendMessage = Notification.Name("didSendMessage")
}
