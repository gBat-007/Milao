//import SwiftUI
//struct PlansTab: View {
//    @Binding var event: Event
//    @Binding var presentAddLocSheet: Bool
//    @State private var showingMapSheet = false
//    var body: some View {
//        NavigationStack{
//            VStack {
//                List(event.plan.locations.indices, id: \.self) { index in
//                    HStack {
//                        Text(event.plan.locations[index].ofPlace.emoji)
//                            .font(.largeTitle)
//                            .foregroundColor(.accentColor)
//                        VStack{
//                            Text(event.plan.locations[index].name)
//                                .fontDesign(.rounded)
//                                .fontWeight(.medium)
//                            Text(event.plan.locations[index].ofPlace.name.trimmingCharacters(in: .whitespacesAndNewlines))
//                                .fontDesign(.default)
//                                .fontWeight(.ultraLight)
//                            Text("Coordinates: \(event.plan.locations[index].coordinate.latitude),\(event.plan.locations[index].coordinate.longitude)")
//                                .fontDesign(.default)
//                                .fontWeight(.ultraLight)
//                        }
//                        .padding()
//                    }
//                    .padding(.vertical, 4)
//                }
//                .listStyle(.insetGrouped)
//                Spacer()
//                HStack{
//                    Spacer()
//                    Button {
//                            showingMapSheet = true
//                        } label: {
//                            Image(systemName: "map")
//                                .padding(10)
//                                .background(.thinMaterial)
//                                .clipShape(Circle())
//                                .shadow(radius: 3)
//                        }
//                        .padding()
//                }
//                .sheet(isPresented: $showingMapSheet) {
//                    NavigationView {
//                        MultiLocationView(locations: $event.plan.locations)
//                            .navigationTitle("Map")
//                            .navigationBarTitleDisplayMode(.inline)
//                            .toolbar {
//                                ToolbarItem(placement: .confirmationAction) {
//                                    Button("Done") {
//                                        showingMapSheet = false
//                                    }
//                                }
//                            }
//                    }
//                    .presentationDetents([.large]) // Full screen
//                    .presentationDragIndicator(.visible) // Optional: adds the drag bar at top
//                }
//            }
//            .sheet(isPresented: $presentAddLocSheet) {
//                if event.places.count > event.plan.locations.count {
//                    AddLocationView(event: $event)
//                } else {
//                    Text("Please add more places so you can add more locations to your event plan.")
//                        .font(.title)
//                        .bold()
//                        .fontDesign(.rounded)
//                        .padding(.horizontal)
//                        .onTapGesture {
//                            presentAddLocSheet = false
//                        }
//                }
//            }
//        }
//    }
//}
