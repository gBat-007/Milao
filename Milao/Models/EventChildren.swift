import SwiftUI
import MapKit
import FirebaseFirestore
import FoundationModels
import GeoToolbox

struct Chat: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var emoji: String
    var messages: [Message]
}

struct Message: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    let text: String
    let isSentByMemberName: String
    let timestamp: Date
}

struct Coordinate: Hashable, Codable, Equatable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


struct Location: Identifiable, Codable, Equatable, Hashable{
    var id: String? = UUID().uuidString
    var name: String
    var coordinate: Coordinate
}

extension Location {
    var locDescriptor: PlaceDescriptor {
        PlaceDescriptor(
            representations: [.coordinate(self.coordinate.clLocation)], commonName: self.name
        )
    }
    var request: MKMapItemRequest {
        MKMapItemRequest(placeDescriptor: locDescriptor)
    }
}

//struct Plan: Identifiable, Codable, Equatable, Hashable{
//    var id: String? = UUID().uuidString
//    var locations: [Location]
//}

struct Place: Identifiable, Equatable, Codable, Hashable{
    var id: String? = UUID().uuidString
    var name: String
    var descriptionAI: String
    var emoji: String
    var location: Location
}
