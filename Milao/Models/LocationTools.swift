import SwiftUI
import FoundationModels
import MapKit

func calculateETA(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> TimeInterval {
    let request = MKDirections.Request()
    request.source = MKMapItem(location: CLLocation(latitude: source.latitude, longitude: source.longitude), address: nil)
    request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
    request.transportType = .automobile

    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    return response.routes.first?.expectedTravelTime ?? 0
}

struct LocationSearchTool: Tool {
    
    let name: String = "searchNearbyLocations"
    let description: String = "Search nearby locations using a query and coordinates."

    typealias ParameterType = Arguments
    typealias ResultType = String

    @Generable
    struct Arguments: Codable {
        @Guide(description: "A natural language query to describe the place you're looking for.")
        let query: String

        @Guide(description: "The latitude of the nearby location to search around.", .range(-90...90))
        let latitude: Double

        @Guide(description: "The longitude of the nearby location to search around.", .range(-180...180))
        let longitude: Double
    }

    @Generable
    struct SearchResult: Codable {
        @Guide(description: "The name of the location result")
        let name: String

        @Guide(description: "A more detailed description or subtitle of the location")
        let subtitle: String

        @Guide(description: "The latitude coordinate of the found destination.", .range(-90...90))
        let latitude: Double

        @Guide(description: "The longitude coordinate of the found destination.", .range(-180...180))
        let longitude: Double

        @Guide(description: "Estimated travel time in seconds from the center coordinate to the destination.")
        let etaSeconds: TimeInterval
    }

    func call(arguments: Arguments) async throws -> String {
        let sourceCoord = CLLocationCoordinate2D(latitude: arguments.latitude, longitude: arguments.longitude)

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = arguments.query
        request.region = MKCoordinateRegion(
            center: sourceCoord,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        let response = try await MKLocalSearch(request: request).start()

        var results: [SearchResult] = []

        for item in response.mapItems.prefix(5) {
            let name = item.name ?? "Unknown"
            // Fixed: Use shortAddress or fullAddress from MKAddress
            let subtitle = item.address?.shortAddress ?? "Unknown"
            let coord = item.location.coordinate

            let eta = try await calculateETA(from: sourceCoord, to: coord)

            let result = SearchResult(
                name: name,
                subtitle: subtitle,
                latitude: coord.latitude,
                longitude: coord.longitude,
                etaSeconds: eta
            )
            results.append(result)
        }

        let formattedResults = results.map { result in
            """
            Name: \(result.name)
            Address: \(result.subtitle)
            Coordinates: (\(result.latitude), \(result.longitude))
            ETA: \(Int(result.etaSeconds / 60)) minutes
            """
        }.joined(separator: "\n\n")
        
        return formattedResults.isEmpty ? "No locations found." : formattedResults
    }
}

