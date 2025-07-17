//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//
import SwiftUI
import ActivityKit

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
                            AddEventMenuView { newEvent in
                                var toAdd = newEvent
                                if let currentMember = currentMember {
                                    toAdd.members.append(currentMember)
                                }
                                events.append(toAdd)
//                                if let soonest = events{
//                                    .filter({ $0.eventDate > Date() })
//                                    .sorted(by: { $0.eventDate < $1.eventDate })
//                                    .first {
//                                        
//                                        TimerManager.shared.startTimer(duration: 10, event: soonest)
//                                    }
//                                }
                                
                                LocalEventStore().save(event: toAdd)
                                saveEventRDB(toAdd) { result in
                                    if case let .failure(error) = result {
                                        print("Failed to save to Firebase: \(error)")
                                    }
                                }
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
            showOnboarding = !hasLaunchedBefore

            observeEventsRDB { newEvents in
                self.events = newEvents
                LocalEventStore().save(events: newEvents)
            }
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
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(Gradient(colors: [event.bgColor1.color, event.bgColor2.color]))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .blur(radius: 0.3) // small blur for softness
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
    @State var textColor: Color = .black
    @State var subTextColor: Color = .gray
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Text(event.eventDate.formatted(.dateTime.weekday().month().day().year()))
                            .font(.subheadline)
                            .foregroundColor(subTextColor)
                    
                    HStack(spacing: 12) {
                        Label("\(event.membersNum)", systemImage: "person.3.fill")
                            .foregroundColor(subTextColor)
                            .font(.subheadline)
                        
                        Label("\(event.placesNum)", systemImage: "mappin.and.ellipse")
                            .foregroundColor(subTextColor)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
            .padding(10)
            .cornerRadius(12)
        }
        .onAppear {
            let isDarkBG = event.bgColor1.color.isDark && event.bgColor2.color.isDark
            textColor = isDarkBG ? .white : .black
            subTextColor = isDarkBG ? .white.opacity(0.8) : .black.opacity(0.6)
        }
    }
    
    #Preview {
        ContentView()
    }
}

extension Color {
    var isDark: Bool {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Perceived brightness algorithm
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 0.5
    }
}
