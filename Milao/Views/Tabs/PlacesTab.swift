import SwiftUI

struct PlacesTab: View {
    @Binding var event: Event
    @Binding var presentAddPlaceSheet: Bool
    @State private var newPlace: Place?
    @State private var showingMapSheet = false
    @EnvironmentObject var viewModel: AuthenticationViewModel

    var body: some View {
        VStack {
            if event.places.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "mappin.and.ellipse")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                    Text("No places yet!")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Button(action: {
                        presentAddPlaceSheet = true
                    }) {
                        Label("Add a Place", systemImage: "plus")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            } else {
                List {
                    Section {
                        ForEach(Array(event.places.enumerated()), id: \.element.id) { index, _ in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                                PlaceRow(place: $event.places[index])
                            }
                            .contextMenu {
                                Button {
                                    routeInMaps(place: event.places[index])
                                } label: {
                                    Label("Route in Maps", systemImage: "map")
                                }
                            }
                        }
                        .onMove(perform: movePlace)
                        .onDelete(perform: deletePlace)
                    }
                }
                .listStyle(.insetGrouped)

                Spacer()

                HStack {
                    Spacer()
                    Button {
                        showingMapSheet = true
                    } label: {
                        Image(systemName: "map")
                            .padding(10)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding()
                }
                .sheet(isPresented: $showingMapSheet) {
                    NavigationView {
                        MultiLocationView(places: $event.places)
                            .navigationTitle("Map")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        showingMapSheet = false
                                    }
                                }
                            }
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .sheet(isPresented: $presentAddPlaceSheet) {
            AddPlaceView(
                draftPlace: $newPlace,
                color1: $event.bgColor1,
                color2: $event.bgColor2,
                previousPlace: event.places.last,
                members: $event.members
            )
            .presentationDetents([.large])
        }
        .onChange(of: newPlace) {
            guard let newPlace else { return }
            let placeToAdd = Place(
                id: UUID().uuidString,
                name: newPlace.name,
                descriptionAI: newPlace.descriptionAI,
                emoji: newPlace.emoji,
                location: newPlace.location
            )
            withAnimation {
                event.places.append(placeToAdd)
            }
            self.newPlace = nil
            event.saveToDatabase { result in
                if case let .failure(error) = result {
                    print("Failed to save event: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - List actions

    func movePlace(from source: IndexSet, to destination: Int) {
        event.places.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func deletePlace(at offsets: IndexSet) {
        event.places.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        event.saveToDatabase { result in
            if case let .failure(error) = result {
                print("Failed to save event: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Routing

    private func routeInMaps(place: Place) {
        // Option 1: If Location has a 'coordinate' property
        let lat = place.location.coordinate.latitude
        let lon = place.location.coordinate.longitude
        
        // Option 2: If Location has direct lat/lon (unlikely)
        // let lat = place.location.latitude
        // let lon = place.location.longitude
        
        guard let url = URL(string: "maps://?daddr=\(lat),\(lon)&dirflg=d") else {
            print("❌ Invalid Maps URL for place: \(place.name)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct PlaceRow: View {
    @Binding var place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(place.emoji)
                    .font(.system(size: 40))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(place.location.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if !place.descriptionAI.isEmpty {
                        Text(place.descriptionAI)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }
}
