
import SwiftUI

struct PlacesTab: View {
    @Binding var event: Event
    @Binding var presentAddPlaceSheet: Bool
    @State private var newPlace: Place?
    @State private var showingMapSheet = false
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(Array(event.places.enumerated()), id: \.element.id) { index, _ in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                            PlaceRow(place: $event.places[index])
                        }
                    }
                    .onMove(perform: movePlace)
                    .onDelete(perform: deletePlace) // <-- added delete handler
                }
            }
            .listStyle(.insetGrouped)
            Spacer()
            HStack{
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
                .presentationDetents([.large]) // Full screen
                .presentationDragIndicator(.visible) // Optional: adds the drag bar at top
            }
        }
        .sheet(isPresented: $presentAddPlaceSheet) {
            AddPlaceView(draftPlace: $newPlace, color1: $event.bgColor1, color2: $event.bgColor2, previousPlace: event.places.last)
                .presentationDetents([.large])
        }
        .onChange(of: newPlace) {
            guard let newPlace else { return }
            let placeToAdd = Place(
                id: UUID().uuidString,
                name: newPlace.name,
                descriptionAI: newPlace.descriptionAI,
                emoji: newPlace.emoji,
                location: Location(id: UUID().uuidString, name: "A Location", coordinate: Coordinate(latitude: 0.0, longitude: 0.0))
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
}




struct PlaceRow: View {
    @Binding var place: Place
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(place.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(place.descriptionAI)
                        .font(.footnote)
//                    HStack(spacing: 12) {
//                        Label("\(event.membersNum)", systemImage: "person.3.fill")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                        
//                        Label("\(event.locationsNum)", systemImage: "mappin.and.ellipse")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                    }
                }
                Spacer()
            }
            .padding(10)
            .cornerRadius(12)
        }
    }
    
}
