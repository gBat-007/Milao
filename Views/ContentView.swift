//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    @State var events = myEvents
    
    var body: some View {
        NavigationStack {
            EventsList(events: $events)
                .navigationTitle("My Events")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Profile", systemImage: "person.circle") {
                            // Profile action
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Event", systemImage: "plus") {
                            // Add event action
                        }
                    }
                }
        }
    }
}

struct EventsList: View {
    @Binding var events: [Event]
    
    var body: some View {
        List {
            ForEach($events) { $event in
                NavigationLink(destination: EventsView(event: $event)) {
                    EventRow(event: $event)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .padding(.vertical, 6)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}


struct EventRow: View {
    @Binding var event: Event
    
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
            .cornerRadius(12)
        }
    }
    
    #Preview {
        ContentView()
    }
}
