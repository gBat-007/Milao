import UIKit
//
//  Events.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import Foundation
import SwiftUI
import FirebaseAuth

struct ChatsTab: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Binding var event: Event
    @Binding var presentAddChatSheet: Bool
    @State var currentMemberName: String = ""
    @State var newMessage: String = ""
    @State private var showGeneralAlert = false
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            List {
                ForEach(Array(event.chats.enumerated()), id: \.element.id) { index, chat in
                    NavigationStack {
                        NavigationLink(destination: ChatsView(eventId: event.id, chatIndex: index, chat: $event.chats[index], thisMember: currentMemberName, newMessage: $newMessage)) {
                            HStack {
                                Text(chat.emoji)
                                    .font(.largeTitle)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading) {
                                    Text(chat.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .onDelete(perform: deleteChat)
                .onAppear {
                    currentMemberName = viewModel.displayName
                    
                    NotificationCenter.default.addObserver(forName: .didSendMessage, object: nil, queue: .main) { _ in
                        event.saveToDatabase()
                    }
                }
                .onDisappear {
                    NotificationCenter.default.removeObserver(self, name: .didSendMessage, object: nil)
                }
            }
            .onAppear {
                currentMemberName = viewModel.displayName
            }
            .onChange(of: newMessage) {
                event.saveToDatabase()
            }
            .listStyle(.insetGrouped)
        }
        .alert("The \"General\" chat cannot be deleted.", isPresented: $showGeneralAlert) {
            Button("OK", role: .cancel) {}
        }
        .tint(Color("bgSwitch"))
        .sheet(isPresented: $presentAddChatSheet) {
            AddChatView { newChat in
                event.chats.append(newChat)
                event.saveToDatabase()
            }
            .presentationDetents([.medium])
        }
    }
    
    private func deleteChat(at offsets: IndexSet) {
        for index in offsets {
                    let chat = event.chats[index]
                    if chat.title == "General" {
                        showGeneralAlert = true
                        return
                    }
                    event.chats.remove(at: index)
                }

            event.saveToDatabase()
    }
}


struct AddChatView: View {
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var emoji = "💬"
//    @State private var membersNum = 1

    var onAdd: (Chat) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat Details")) {
                    TextField("Title", text: $title)
                    HStack{
                        Text("Emoji ")
                            .fontDesign(.rounded)
                        EmojiKeyboardButton(emoji: $emoji)
                            .frame(width: 50, height: 50)
                            .overlay(RoundedRectangle(cornerRadius: 45).stroke(Color.gray.opacity(0.4)).blur(radius: 20.0))
                    }
//                    Stepper("Members: \(membersNum)", value: $membersNum, in: 1...100)
                }
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newChat = Chat(title: title, emoji: emoji, messages: [Message(text: "Welcome to the \(title) chat.", isSentByMemberName: "Admin", timestamp: Date.now)])
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
