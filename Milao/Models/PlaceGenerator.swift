import SwiftUI
import FoundationModels
import Foundation
import CoreLocation

struct BlinkingImage: View {
    @State private var isVisible = true

    var body: some View {
        Image(systemName: "sparkles") // or any image you want
            .resizable()
            .scaledToFit()
            .frame(width: 25, height: 25)
            .opacity(isVisible ? 1.0 : 0.2)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Models

@Generable
struct PlaceQuestion {
    @Guide(description: "A multiple-choice question about the place.")
    var question: String?

    @Guide(description: "2–4 answer options.", .count(2...4))
    var options: [String]?
    
    @Guide(description: "A short place description based on all user choices.")
    var description: String?
}

@Generable
struct EmojiGenerator {
    @Guide(description: "An emoji representing the place type.")
    var emoji: String
}

// MARK: - Location

func resolveLocationName(from coordinate: CLLocationCoordinate2D?) async -> String {
    guard let coordinate else { return "your area" }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    do {
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks.first?.locality ?? placemarks.first?.name ?? "your area"
    } catch {
        return "your area"
    }
}

func resolveExactLocationName(from coordinate: CLLocationCoordinate2D?) async -> String {
    guard let coordinate else { return "your area" }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    do {
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return "your area" }

        // 1) Areas of interest (schools, parks, venues, etc.)
        if let aoi = placemark.areasOfInterest?.first, !aoi.isEmpty {
            return aoi
        }

        // 2) Best display name (often POI or building)
        if let name = placemark.name, !name.isEmpty {
            return name
        }

        // 3) Neighborhood/borough
        if let subLocality = placemark.subLocality, !subLocality.isEmpty {
            return subLocality
        }

        // 4) Street + number
        let street = placemark.thoroughfare
        let number = placemark.subThoroughfare
        if let street = street, !street.isEmpty, let number = number, !number.isEmpty {
            return "\(number) \(street)"
        } else if let street = street, !street.isEmpty {
            return street
        }

        // 5) City
        if let locality = placemark.locality, !locality.isEmpty {
            return locality
        }

        // 6) Region / Country fallbacks
        if let admin = placemark.administrativeArea, !admin.isEmpty {
            return admin
        }
        if let country = placemark.country, !country.isEmpty {
            return country
        }

        // 7) Final fallback
        return "your area"
    } catch {
        return "your area"
    }
}
