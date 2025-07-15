import SwiftUI
import MapKit
import Contacts
import CoreLocation

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var member: Member

    @State private var tempName: String
    @State private var tempLocation: String
    @State private var coordinate: CLLocationCoordinate2D?

    @StateObject private var completerDelegate = SearchCompleterDelegate()
    private let searchCompleter = MKLocalSearchCompleter()
    private let geocoder = CLGeocoder()

    init(member: Binding<Member>) {
        _member = member
        _tempName = State(initialValue: member.wrappedValue.name)
        _tempLocation = State(initialValue: "")
        _coordinate = State(initialValue: member.wrappedValue.coordinate)

        searchCompleter.resultTypes = .address
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Name") {
                    TextField("Name", text: $tempName)
                }

                Section("Your Location") {
                    TextField("Search Location", text: $tempLocation)
                        .onChange(of: tempLocation) { _, newValue in
                            searchCompleter.queryFragment = newValue
                        }

                    if !completerDelegate.results.isEmpty {
                        Section {
                            ForEach(completerDelegate.results, id: \.self) { result in
                                Button {
                                    selectLocation(result)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(result.title).bold()
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            }
                        }
                    }

                    if let coord = coordinate {
                        Map {
                            Marker("Your Location", coordinate: coord)
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    } else {
                        Text("No location selected")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        member.name = tempName
                        if let coord = coordinate {
                            member.locationPlaceID = tempLocation
                            member.coordinate = coord
                        }
                        dismiss()
                    }
                    .disabled(tempName.isEmpty || coordinate == nil || tempLocation.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                searchCompleter.delegate = completerDelegate

                    if let coord = coordinate {
                        reverseGeocode(coord: coord)
                    }
            }
        }
    }

    private func selectLocation(_ result: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: request).start { response, _ in
            guard let loc = response?.mapItems.first?.location else { return }
            let coord = loc.coordinate
            self.coordinate = coord
            self.tempLocation = "\(result.title), \(result.subtitle)"
            self.reverseGeocode(coord: coord)
        }
    }

    private func reverseGeocode(coord: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }

            if let postalAddr = placemark.postalAddress {
                let formatted = CNPostalAddressFormatter.string(from: postalAddr, style: .mailingAddress)
                self.tempLocation = formatted
            } else {
                let parts = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ]
                self.tempLocation = parts.compactMap { $0 }.joined(separator: ", ")
            }
        }
    }
}
