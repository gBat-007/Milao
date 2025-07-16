
import SwiftUI




struct PlacesTab: View {
    @Binding var places: [Place]
    @Binding var presentAddPlaceSheet: Bool
    @State private var newPlace: Place?
    @Binding var bgColor1: CodableColor
    @Binding var bgColor2: CodableColor
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach($places, id: \.id) { $place in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                            PlaceRow(place: $place)
                        }
                    }
                    .onMove(perform: movePlace)
                    .moveDisabled(false) // ← allows drag without EditMode
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddPlaceSheet, onDismiss: {
            if let place = newPlace {
                places.append(
                    Place(
                        id: UUID().uuidString,
                        name: place.name,
                        descriptionAI: place.descriptionAI,
                        emoji: place.emoji
                    )
                )
                newPlace = nil
            }
        }) {
            AddPlaceView(draftPlace: $newPlace, color1: $bgColor1, color2: $bgColor2)
                .presentationDetents([.fraction(0.7)])
        }
    }
    
    func movePlace(from source: IndexSet, to destination: Int) {
        places.move(fromOffsets: source, toOffset: destination)
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
                        .font(.subheadline)
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
