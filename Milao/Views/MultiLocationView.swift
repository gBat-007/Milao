//
//  LocationsView.swift
//  Milao
//
//  Created by Gautam Bansal on 11/07/25.
//
import SwiftUI
import MapKit
import GeoToolbox

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


struct MultiLocationView: View {
    @Binding var locations: [Location]
    @State private var position: MapCameraPosition = .automatic // or use .region if you prefer
    @State private var mapItems: [MKMapItem] = []
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
        Map(initialPosition: position) {
            ForEach(mapItems, id:\.name) { itm in
                Marker(item: itm)
                    .mapItemDetailSelectionAccessory(.callout)
            }
        }
        .onAppear {
            Task {
                await getMapItems(locations)
                let newRegion = regionThatFits(locations: locations)
                position = .region(newRegion)
            }
        }
        .onChange(of: locations) {
            let newRegion = regionThatFits(locations: locations)
            position = .region(newRegion)
        }
        .ignoresSafeArea()
    }
    
    func getMapItems(_: [Location]) async {
        for location in locations {
            let newItem = try? await location.request.mapItem
            if let nwItem = newItem {
                mapItems.append(nwItem)
            }
        }
    }
}
