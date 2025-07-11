//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                        Tab("Home", systemImage: "house") {
                            List(myEvents) { event in
                                EventRow(event: event)
                                    .padding(.vertical, 4)
                            }
                            .listStyle(.insetGrouped)
                            .navigationTitle("My Events")
                        }
                        Tab("Chats", systemImage: "gear") {
                            ChatsView()
                        }
                        Tab("Settings", systemImage: "gear") {
                            Text("dog")
                        }
                    }
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(event.membersNum)", systemImage: "person.3.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Label("\(event.locationsNum)", systemImage: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
    }
    
    #Preview {
        ContentView()
    }
}
