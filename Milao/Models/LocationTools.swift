import SwiftUI
import FoundationModels
import MapKit

func calculateETA(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> TimeInterval {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
    request.transportType = .automobile

    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    return response.routes.first?.expectedTravelTime ?? 0
}

struct LocationSearchTool: Tool {
    let name: String = "searchNearbyLocations"
    let description: String = "Search nearby locations using a query and coordinates."

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

    func call(arguments: Arguments) async throws -> ToolOutput {
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
            let subtitle = item.placemark.title ?? "Unknown"
            let coord = item.placemark.coordinate

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

        return ToolOutput(GeneratedContent(results))
    }
}
