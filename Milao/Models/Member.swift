import CoreLocation
import Foundation
import FirebaseAuth

struct Member: Codable, Identifiable, Equatable, Hashable {
    var id: String //Firebase UID from Auth
    var name: String //Display Name from Auth
    var locationPlaceID: String //Format: latitude,longitude e.g. '45.006,65.007'
    var profilePhotoURL: String? //URL from Google/Apple Sign In
    var eventIDs: [String] // Stored in Firebase as array
    
    // Coding keys for Firebase mapping
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case locationPlaceID
        case profilePhotoURL
        case eventIDs
    }
    
    /// Initialize from Firebase Auth user (for creating new users)
    init(from user: User, locationPlaceID: String = "47.6,-122.3") {
        self.id = user.uid
        self.name = user.displayName ?? "Unknown User"
        self.locationPlaceID = locationPlaceID
        self.profilePhotoURL = user.photoURL?.absoluteString
        self.eventIDs = [] // Start with no events
    }
    
    /// Standard initializer (for manual creation and Firebase decoding)
    init(id: String, name: String, locationPlaceID: String, profilePhotoURL: String? = nil, eventIDs: [String] = []) {
        self.id = id
        self.name = name
        self.locationPlaceID = locationPlaceID
        self.profilePhotoURL = profilePhotoURL
        self.eventIDs = eventIDs
    }
    
    ///Convenience Initialiser - Decode from Firebase dictionary
    init?(dictionary: [String: Any]) {
            guard let id = dictionary["id"] as? String,
                  let name = dictionary["name"] as? String,
                  let locationPlaceID = dictionary["locationPlaceID"] as? String
            else {
                return nil // Return nil if required fields are missing
            }
            
            self.id = id
            self.name = name
            self.locationPlaceID = locationPlaceID
            self.profilePhotoURL = dictionary["profilePhotoURL"] as? String
            self.eventIDs = dictionary["eventIDs"] as? [String] ?? []
    }
    
    /// Convert to dictionary for Firebase
    func toFirebaseDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "locationPlaceID": locationPlaceID,
            "eventIDs": eventIDs
        ]
        if let photoURL = profilePhotoURL {
            dict["profilePhotoURL"] = photoURL
        }
        return dict
    }
}

extension Member {
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

