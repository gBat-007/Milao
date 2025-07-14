//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import SwiftUI

struct ContentView: View {
    @State private var events: [Event] = []
    @State private var profileDoesNotWork = false
    @State private var showAddMenu = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("memberData") private var memberData: Data?

    @State private var showOnboarding = false
    @State private var currentMember: Member?

    func currentMemberBinding() -> Binding<Member>? {
        guard let currentMember else { return nil }
        return Binding(
            get: { currentMember },
            set: { self.currentMember = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            EventsList(events: $events)
                .navigationTitle("My Events")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Profile", systemImage: profileDoesNotWork ? "person.slash" : "person.circle" ) {
                            if let decoded = Member.decode(from: memberData) {
                                currentMember = decoded
                            } else {
                                profileDoesNotWork.toggle()
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Event", systemImage: "plus") {
                            showAddMenu = true
                        }
                        .sheet(isPresented: $showAddMenu) {
                            CreateEventView { newEvent in
                                events.append(newEvent)
                                LocalEventStore().save(event: newEvent)
                            }
                        }
                    }
                }
                .sheet(item: $currentMember) { member in
                    NavigationStack {
                        ProfileView(member: Binding(
                            get: { currentMember ?? member },
                            set: { updated in
                                currentMember = updated
                                memberData = updated.encodeToData()
                            }
                        ))
                    }
                }
        }
        .onAppear {
            events = LocalEventStore().fetchEvents()
            showOnboarding = !hasLaunchedBefore
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { member in
                memberData = member.encodeToData()
                hasLaunchedBefore = true
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
                        
                        Label("\(event.placesNum)", systemImage: "mappin.and.ellipse")
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
