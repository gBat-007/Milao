import Foundation
import CoreLocation
import FirebaseFirestore

struct Member: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var locationPlaceID: String
}


extension Member {
    func encodeToData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(from data: Data?) -> Member? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(Member.self, from: data)
    }

    var coordinate: CLLocationCoordinate2D? {
        get {
            let parts = locationPlaceID.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: parts[0], longitude: parts[1])
        }
        set {
            if let newValue = newValue {
                locationPlaceID = "\(newValue.latitude),\(newValue.longitude)"
            } else {
                locationPlaceID = ""
            }
        }
    }
}

