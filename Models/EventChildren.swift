import SwiftUI
import MapKit
import FirebaseFirestore
import FoundationModels

struct Coordinate: Hashable, Codable, Equatable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


struct Location: Identifiable, Codable, Equatable{
    var id: String? = UUID().uuidString
    var name: String
    var coordinate: Coordinate
    var ofPlace: Place
}

struct Plan: Identifiable, Codable, Equatable{
    var id: String? = UUID().uuidString
    var locations: [Location]
}

@Generable
struct Place: Identifiable, Equatable, Codable{
    var id: String? = UUID().uuidString
    var name: String
    var descriptionAI: String
    var emoji: String
}
