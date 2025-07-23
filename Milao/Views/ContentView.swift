//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
////
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import SwiftUI
import ActivityKit
import WatchConnectivity
import UIKit
import AlarmKit

struct ContentView: View {
    @State private var events: [Event] = []
    @State private var profileDoesNotWork = false
    @State private var showAddMenu = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("memberData") private var memberData: Data?

    @State private var showOnboarding = false
    @State private var currentMember: Member?
    @State private var showProfileSheet = false // ✅ New flag

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
                        Button("Settings", systemImage: "gear") {
                            if let decoded = Member.decode(from: memberData) {
                                currentMember = decoded
                                showProfileSheet = true // ✅ Show manually
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
                                Task {
                                    let granted = try await AlarmManager.shared.requestAuthorization()
                                    if granted == .authorized {
                                                        print("✅ Alarm permission granted.")
                                                    } else {
                                                        print("❌ Alarm permission denied.")
                                                    }
                                    await scheduleAlarm(for: newEvent)
                                }
                                saveEventRDB(newEvent) { result in
                                    if case let .failure(error) = result {
                                        print("❌ Failed to save to Firebase: \(error)")
                                    } else {
//                                        if var soonest = events
//                                            .filter({ $0.eventDate > Date() })
//                                            .sorted(by: { $0.eventDate < $1.eventDate })
//                                            .first {
//                                            
//                                            TimerManager.shared.startSimpleTimer(to: soonest.asWidgetEvent)
//                                        }
                                        print("✅ Event saved to Firebase.")
                                    }
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showProfileSheet) { // ✅ Controlled manually
                    if let decoded = Member.decode(from: memberData) {
                        NavigationStack {
                            AllSettingsView(member: Binding(
                                get: { decoded },
                                set: { updated in
                                    self.currentMember = updated
                                    memberData = updated.encodeToData()
                                }
                            ), events: $events)
                            .navigationTitle("My Profile")
                            .navigationBarTitleDisplayMode(.inline)
//                            .toolbar {
//                                ToolbarItem(placement: .confirmationAction) {
//                                    Button("Done") {
//                                        showProfileSheet = false
//                                    }
//                                }
//                            }
                        }
                    } else {
                        Text("No member loaded")
                    }
                }
        }
        .onAppear {
            showOnboarding = !hasLaunchedBefore
            
            let widgets = events.map { $0.asWidgetEvent }
            WidgetEventStore.shared.widgetEvents = widgets
            PhoneSessionManager.shared.send(widgetEvents: widgets)

            if let data = memberData,
               let decoded = try? JSONDecoder().decode(Member.self, from: data) {
                currentMember = decoded
            } else {
                print("⚠️ Failed to decode member data")
                profileDoesNotWork = true
            }

            observeEventsRDB { newEvents in
                print("🔄 Firebase gave \(newEvents.count) events")

                self.events = newEvents

                let widgets = newEvents.map { $0.asWidgetEvent }
                WidgetEventStore.shared.widgetEvents = widgets

                PhoneSessionManager.shared.send(widgetEvents: widgets)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("🔗 Is Watch reachable? \(WCSession.default.isReachable)")
            }
            
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { member in
                memberData = member.encodeToData()
                hasLaunchedBefore = true
                currentMember = member
            }
        }
    }
}

struct EventsList: View {
    @Binding var events: [Event]
    @State private var showDeleteConfirmation = false
    @State private var eventToDeleteIndex: Int?

    var body: some View {
        List {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                let eventBinding = Binding(
                    get: { events[index] },
                    set: { events[index] = $0 }
                )

                NavigationLink(destination: EventsView(event: eventBinding)) {
                    EventRow(event: eventBinding)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(event.colorGradient)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .blur(radius: 0.3)
//                        .padding(.vertical, 6)
                }
                .swipeActions {
                    if event.ownerID == UIDevice.current.identifierForVendor?.uuidString {
                        Button(role: .destructive) {
                            eventToDeleteIndex = index
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .confirmationDialog(
            "Are you sure you want to delete \"\(eventToDeleteIndex.map { events[$0].title } ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let index = eventToDeleteIndex {
                    let event = events[index]
                    event.deleteFromDatabase { _ in }
                    events.remove(at: index)
                    eventToDeleteIndex = nil
                }
            }
            Button("Cancel", role: .cancel) {
                eventToDeleteIndex = nil
            }
        }
    }
}



struct EventRow: View {
    @Binding var event: Event
    @State var textColor: Color = .black
    @State var subTextColor: Color = .gray
    @State var showOwnerPopover: Bool = false
    @State var showOwnerAlert: Bool = false
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(textColor)
                        if event.ownerID == UIDevice.current.identifierForVendor?.uuidString {
                            Image(systemName: "crown.fill")
                                .foregroundColor(textColor)
                                .onTapGesture {
                                            #if os(iOS)
                                            if UIDevice.current.userInterfaceIdiom == .pad {
                                                showOwnerPopover = true
                                            } else {
                                                withAnimation {
                                                    showOwnerAlert.toggle()
                                                }
                                            }
                                            #else
                                            showOwnerPopover = true
                                            #endif
                                }
                                .popover(isPresented: $showOwnerPopover) {
                                        Text("You are the owner of this event.")
                                            .padding()
                                            .frame(width: 200)
                                }
                                .alert("Owner", isPresented: $showOwnerAlert) {
                                    Button("OK", role: .cancel) { }
                                } message: {
                                    Text("You're the owner of \(event.title).")
                                }
                                .tint(Color("bgSwitch"))
                        }
                    }
                    
                    
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
