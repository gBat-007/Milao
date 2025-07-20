import SwiftUI
import MapKit
struct EventsView: View {
    @Binding var event: Event
    @State private var selectedTab = 0

    @State private var presentAddMemberSheet = false
    @State private var presentAddPlaceSheet = false
    @State private var presentAddPlanSheet = false
    @State private var presentAddChatSheet = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                
                Tab("Members", systemImage: "person.3.fill", value: 0) {
                    MembersTab(event: $event,
                               presentAddMemberSheet: $presentAddMemberSheet,
                               inviteCode: event.inviteCode)
                }

                Tab("Locations", systemImage: "mappin.and.ellipse", value: 1) {
                    PlacesTab(event: $event,
                              presentAddPlaceSheet: $presentAddPlaceSheet)
                }

                Tab("Plan", systemImage: "map", value: 2) {
                    PlansTab(event: $event,
                             presentAddLocSheet: $presentAddPlanSheet)
                }

                Tab("Chats", systemImage: "message", value: 3) {
                    ChatsTab(event: $event,
                             presentAddChatSheet: $presentAddChatSheet)
                }

                Tab("Settings", systemImage: "gear", value: 4) {
                    SettingsTab(event: $event)
                }
            }
            .navigationTitle($event.title)
            .onChange(of: event.title) {
                event.saveToDatabase()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    switch selectedTab {
                    case 0:
                        Button {
                            presentAddMemberSheet = true
                        } label: {
                            Label("Add Member", systemImage: "plus")
                        }
                    case 1:
                        Button {
                            presentAddPlaceSheet = true
                        } label: {
                            Label("Add Place", systemImage: "plus")
                        }
                    case 2:
                        Button {
                            presentAddPlanSheet = true
                        } label: {
                            Label("Add Plan", systemImage: "plus")
                        }
                    case 3:
                        Button {
                            presentAddChatSheet = true
                        } label: {
                            Label("New Chat", systemImage: "plus.bubble")
                        }
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
}
