//
//  LocationsView.swift
//  Milao
//
//  Created by Gautam Bansal on 11/07/25.
//
import SwiftUI
import MapKit

func regionThatFits(locations: [Location]) -> MKCoordinateRegion {
    guard !locations.isEmpty else {
        return MKCoordinateRegion() // default fallback
    }

    let latitudes = locations.map { $0.coordinate.latitude }
    let longitudes = locations.map { $0.coordinate.longitude }

    let minLat = latitudes.min()!
    let maxLat = latitudes.max()!
    let minLon = longitudes.min()!
    let maxLon = longitudes.max()!

    let centerLat = (minLat + maxLat) / 2
    let centerLon = (minLon + maxLon) / 2

    let spanLat = (maxLat - minLat) * 1.5 // Add some padding
    let spanLon = (maxLon - minLon) * 1.5

    return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
        span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.01), longitudeDelta: max(spanLon, 0.01))
    )
}


struct PlansView: View {
    @Binding var locations: [Location]
    @State private var region = MKCoordinateRegion()
    //    @State private var region: MKCoordinateRegion
    
    //    init(locations: [Location]) {
    //        self.locations = locations
    //        if let first = locations.first {
    //            _region = State(initialValue: MKCoordinateRegion(
    //                center: first.coordinate.clLocation,
    //                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    //            ))
    //        } else {
    //            _region = State(initialValue: MKCoordinateRegion(
    //                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
    //                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    //            ))
    //        }
    //    }
    
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
        .onAppear {
            region = regionThatFits(locations: locations)
        }
        .onChange(of: locations) { newLocations in
            region = regionThatFits(locations: newLocations)
        }
        .ignoresSafeArea()
    }
}
