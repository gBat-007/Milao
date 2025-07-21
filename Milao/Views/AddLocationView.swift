
import SwiftUI
import MapKit
import FoundationModels


struct AddLocationView: View {
    @Binding var event: Event
    @Environment(\.dismiss) private var dismiss
    enum LocationAddMode: String, CaseIterable {
        case search = "Search"
        case ai = "AI Recommend"
    }

    @State private var selectedMode: LocationAddMode = .search
    @State private var closeTo: Coordinate = .init(latitude: 0.0, longitude: 0.0)
    @State private var isCoordinateReady: Bool = false
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
                        event.plan.locations.append(Location(name: mapItem.name ?? "Unknown Name", coordinate: Coordinate(latitude: mapItem.location.coordinate.latitude, longitude: mapItem.location.coordinate.longitude), ofPlace: event.places[event.plan.locations.count]))
                        event.saveToDatabase() { result in
                            if case let .failure(error) = result {
                                print("Failed to save event: \(error.localizedDescription)")
                            }
                        }
                        dismiss()
                    }
                } else {
                        AIRecommendationView(event: $event) { selectedLocation in
                            event.plan.locations.append(selectedLocation)
                            event.saveToDatabase() { result in
                                if case let .failure(error) = result {
                                    print("Failed to save event: \(error.localizedDescription)")
                                }
                            }
                            dismiss()
                        }
                    }
            }
            
                
        }
        .onAppear {
            if event.plan.locations.count == 0 && event.places.count > 0 {
                if let decoded = Member.decode(from: memberData) {
                    closeTo = Coordinate(latitude: decoded.coordinate?.latitude ?? 0.0, longitude: decoded.coordinate?.longitude ?? 0.0)
                }
            } else if event.places.count > event.plan.locations.count {
                if let latestLoc = event.plan.locations.last {
                    closeTo = latestLoc.coordinate
                }
            }
            
            // Delay slightly to ensure UI updates
            DispatchQueue.main.async {
                isCoordinateReady = true
            }
        }
    }
}
