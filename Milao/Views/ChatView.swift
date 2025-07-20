import SwiftUI

struct ChatsView: View {
    @Binding var chat: Chat
    var thisMember: String
    @Binding var newMessage: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chat.messages) { message in
                            HStack {
                                if message.isSentByMemberName == thisMember {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chat.messages.count) { _ in
                    if let last = chat.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
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
            .padding(.vertical, 5)
            .background(Color(UIColor.systemGray6))
        }
        .navigationTitle("Chats")
    }
    
    func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        chat.messages.append(Message(text: trimmed, isSentByMemberName: thisMember))
        newMessage = ""
    }
}

