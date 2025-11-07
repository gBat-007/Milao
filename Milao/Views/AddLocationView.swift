import SwiftUI
import MapKit
import FoundationModels

struct AddLocationView: View {
    var placeType: String
    var placeDesc: String
    var previousPlace: Place?
    @Binding var members: [Member]
    let onComplete: (Location) -> Void

    enum SheetType: Identifiable {
        case search, ai

        var id: Int {
            hashValue
        }
    }

    @State private var activeSheet: SheetType?
    @State private var isCoordinateReady: Bool = false
    @State private var closeTo: Coordinate = .init(latitude: 47.6, longitude: -122.3)
    @State private var useAverageETA: Bool = false
    @AppStorage("memberData") private var memberData: Data?

    var body: some View {
        VStack(spacing: 20) {
            Text("How would you like to choose a location?")
                .font(.title3)
                .bold()
                .padding(.top)

            // Custom Card Buttons
            VStack(spacing: 12) {
                
                Button {
                    activeSheet = .search
                } label: {
                    cardButton(title: "Search", subtitle: "Manually find a place", systemImage: "magnifyingglass")
                }
                
                Button {
                    activeSheet = .ai
                } label: {
                    cardButton(title: "AI Recommend", subtitle: "Get a suggestion based on description", systemImage: "sparkles")
                }
                
            }
            .padding(.horizontal)

            Spacer()
        }
        .sheet(item: $activeSheet) { sheet in
            VStack(alignment: .center, spacing: 12) {
                
                Text(placeType)
                    .font(.headline)
                    .bold()

                Text(placeDesc)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider()

                if isCoordinateReady {
                    switch sheet {
                    case .search:
                        SearchLocationView(near: closeTo.clLocation, useAvg: useAverageETA, members: members) { mapItem in
                            onComplete(
                                Location(
                                    name: mapItem.name ?? "Unknown Name",
                                    coordinate: Coordinate(
                                        latitude: mapItem.location.coordinate.latitude,
                                        longitude: mapItem.location.coordinate.longitude
                                    )
                                )
                            )
                            activeSheet = nil
                        }
                    case .ai:
                        AIRecommendationView(placeType: placeType, placeDesc: placeDesc) { selectedLocation in
                            onComplete(selectedLocation)
                            activeSheet = nil
                        }
                    }
                } else {
                    ProgressView("Preparing location…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if let prevPlace = previousPlace {
                closeTo = prevPlace.location.coordinate
            } else {
//                let member =
                closeTo = Coordinate(latitude: 47.6,
                                     longitude: -122.3)
                useAverageETA = true
            }

            DispatchQueue.main.async {
                isCoordinateReady = true
            }
        }
    }

    // MARK: - Custom Card Button
    @ViewBuilder
    private func cardButton(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
    }
}
