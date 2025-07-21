import SwiftUI
import MapKit
import Contacts
import CoreLocation
internal import Combine

class SearchCompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
        print("SearchCompleter error: \(error.localizedDescription)")
    }
}

// MARK: - Manager that owns the completer
class SearchLocationManager: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    init(near coordinate: CLLocationCoordinate2D) {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.results = []
        }
    }
}


struct SearchLocationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var mapItems: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSearching = false
    @State private var travelInfo: [MKMapItem: (eta: TimeInterval, distance: CLLocationDistance)] = [:]

    let searchCenter: CLLocationCoordinate2D
    let onLocationSelected: (MKMapItem) -> Void

    init(
        near coordinate: CLLocationCoordinate2D,
        onLocationSelected: @escaping (MKMapItem) -> Void
    ) {
        self.searchCenter = coordinate
        self.onLocationSelected = onLocationSelected
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Search for a place", text: $searchText)
                        .onSubmit {
                            runSearch()
                        }
                        .onChange(of: searchText) { _, newValue in
                            if newValue.isEmpty {
                                mapItems = []
                                selectedMapItem = nil
                                selectedCoordinate = nil
                                travelInfo = [:]
                            }
                        }

                    if isSearching {
                        ProgressView("Searching...")
                    }

                    if !mapItems.isEmpty {
                        Section("Results") {
                            ForEach(mapItems, id: \.self) { item in
                                Button {
                                    selectMapItem(item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "Unnamed Location").bold()
                                        if let address = item.placemark.title {
                                            Text(address)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }

                                        if let info = travelInfo[item] {
                                            let minutes = Int(info.eta / 60)
                                            let km = String(format: "%.1f km", info.distance / 1000)
                                            Text("\(minutes) min drive • \(km)")
                                                .font(.footnote)
                                                .foregroundColor(.blue)
                                        } else {
                                            ProgressView()
                                                .scaleEffect(0.6)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }

                if let coord = selectedCoordinate {
                    Map {
                        Marker("Selected", coordinate: coord)
                    }
                    .frame(height: 200)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Pick a Location")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        if let mapItem = selectedMapItem {
                            onLocationSelected(mapItem)
                            dismiss()
                        }
                    }
                    .disabled(selectedMapItem == nil)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func runSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        searchNearbyPlaces(query: searchText, near: searchCenter) { items in
            self.mapItems = items
            self.travelInfo = [:]
            self.isSearching = false

            Task {
                for item in items {
                    let destination = item.placemark.coordinate
                    do {
                        let eta = try await calculateETA(from: searchCenter, to: destination)
                        let distance = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
                            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
                        DispatchQueue.main.async {
                            travelInfo[item] = (eta: eta, distance: distance)
                        }
                    } catch {
                        print("ETA fetch failed for \(item.name ?? "unknown"): \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func selectMapItem(_ item: MKMapItem) {
        selectedMapItem = item
        selectedCoordinate = item.placemark.coordinate
        searchText = item.name ?? ""
    }

    private func searchNearbyPlaces(query: String, near coordinate: CLLocationCoordinate2D, completion: @escaping ([MKMapItem]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 50000, longitudinalMeters: 50000)

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Search failed: \(error.localizedDescription)")
                    completion([])
                    return
                }

                completion(response?.mapItems ?? [])
            }
        }
    }

    private func calculateETA(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        return response.routes.first?.expectedTravelTime ?? 0
    }
}
