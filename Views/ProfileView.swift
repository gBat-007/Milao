//
//  ProfileView.swift
//  Milao
//
//  Created by Gautam Bansal on 13/07/25.
//


import SwiftUI
import MapKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var member: Member

    @State private var tempName: String
    @State private var tempLocation: String
    @State private var coordinate: CLLocationCoordinate2D?

    @StateObject private var completerDelegate = SearchCompleterDelegate()
    private let searchCompleter = MKLocalSearchCompleter()

    init(member: Binding<Member>) {
        _member = member
        _tempName = State(initialValue: member.wrappedValue.name)
        _tempLocation = State(initialValue: member.wrappedValue.locationPlaceID)
        _coordinate = State(initialValue: member.wrappedValue.coordinate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Name")) {
                    TextField("Name", text: $tempName)
                }

                Section(header: Text("Your Location")) {
                    TextField("Search Location", text: $tempLocation)
                        .onChange(of: tempLocation) {
                            searchCompleter.queryFragment = tempLocation
                        }

                    if !completerDelegate.results.isEmpty {
                        List {
                            ForEach(completerDelegate.results, id: \.self) { result in
                                Button {
                                    tempLocation = result.title + ", " + result.subtitle
                                    fetchCoordinate(for: result) { coord in
                                        self.coordinate = coord
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(result.title).bold()
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle).font(.subheadline).foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                    }

                    if let coord = coordinate {
                        Map {
                            Marker("Location", coordinate: coord)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        member.name = tempName
                        if let coord = coordinate {
                            member.locationPlaceID = "\(coord.latitude),\(coord.longitude)"
                        }
                        dismiss()
                    }
                    .disabled(tempName.isEmpty || coordinate == nil)
                }
            }
            .onAppear {
                searchCompleter.resultTypes = .address
                searchCompleter.delegate = completerDelegate
            }
        }
    }

    private func fetchCoordinate(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            completionHandler(response?.mapItems.first?.placemark.coordinate)
        }
    }
}
