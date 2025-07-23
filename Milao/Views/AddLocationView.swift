
import SwiftUI
import MapKit
import FoundationModels


struct AddLocationView: View {
    var placeType: String
    var placeDesc: String
    var previousPlace: Place?
    let onComplete: (Location) -> Void

    enum LocationAddMode: String, CaseIterable {
        case search = "Search"
        case ai = "AI Recommend"
    }

    @State private var selectedMode: LocationAddMode = .search
    @State private var isCoordinateReady: Bool = false
    @State private var closeTo: Coordinate = .init(latitude: 0.0, longitude: 0.0)
    @AppStorage("memberData") private var memberData: Data?
    
    var body: some View {
        VStack{
            Picker("Choose a method", selection: $selectedMode) {
                ForEach(LocationAddMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                        .font(.title)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            if isCoordinateReady {
                if selectedMode == .search {
                    SearchLocationView(near: closeTo.clLocation) { mapItem in
                        onComplete(
                            Location(
                                name: mapItem.name ?? "Unknown Name",
                                coordinate: Coordinate(
                                    latitude: mapItem.location.coordinate.latitude,
                                    longitude: mapItem.location.coordinate.longitude
                                )
                            )
                        )
                    }
                } else {
                        AIRecommendationView(placeType: placeType, placeDesc: placeDesc) { selectedLocation in
                            onComplete(selectedLocation)
                        }
                    }
            }
            
                
        }
        .onAppear {
            if let prevPlace = previousPlace {
                closeTo = prevPlace.location.coordinate
            } else {
                let member = Member.decode(from: memberData)
                closeTo = Coordinate(latitude: member?.coordinate?.latitude ?? 0.0, longitude: member?.coordinate?.longitude ?? 0.0)
            }
            
            // Delay slightly to ensure UI updates
            DispatchQueue.main.async {
                isCoordinateReady = true
            }
        }
    }
}
