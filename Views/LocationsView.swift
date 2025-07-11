//
//  LocationsView.swift
//  Milao
//
//  Created by Gautam Bansal on 11/07/25.
//
import SwiftUI
import MapKit

struct LocationsView: View {
    var locations: [Location]

    @State private var region: MKCoordinateRegion

    init(locations: [Location]) {
        self.locations = locations
        if let first = locations.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: first.coordinate.clLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            MapAnnotation(coordinate: location.coordinate.clLocation) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                    Text(location.name)
                        .font(.caption)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(6)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
