import SwiftUI
import MapKit
struct EventsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthenticationViewModel
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
                               inviteCode: event.id)
                    .tint(event.bgColor2.resolved(for: colorScheme))
                    .environmentObject(viewModel)
                }

                Tab("Plan", systemImage: "map", value: 1) {
                    PlacesTab(event: $event,
                              presentAddPlaceSheet: $presentAddPlaceSheet)
                    .tint(event.bgColor2.resolved(for: colorScheme))
                    .environmentObject(viewModel)
                }

//                Tab("Plan", systemImage: "map", value: 2) {
//                    PlansTab(event: $event,
//                             presentAddLocSheet: $presentAddPlanSheet)
//                    .tint(event.bgColor2.resolved(for: colorScheme))
//                }

                Tab("Chats", systemImage: "message", value: 2) {
                    ChatsTab(event: $event,
                             presentAddChatSheet: $presentAddChatSheet)
                    .tint(event.bgColor2.resolved(for: colorScheme))
                    .environmentObject(viewModel)
                }

                Tab("Settings", systemImage: "gear", value: 3) {
                    SettingsTab(event: $event)
                        .environmentObject(viewModel)
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
        .tint(event.bgColor1.resolved(for: colorScheme))
    }
}
