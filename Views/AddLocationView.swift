//
//  AddPlanView.swift
//  Milao
//
//  Created by yash on 17/07/25.
//
import SwiftUI
import MapKit
import FoundationModels

func calculateETA(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> TimeInterval {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
    request.transportType = .automobile

    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    return response.routes.first?.expectedTravelTime ?? 0
}



//func averageETA(to destination: CLLocationCoordinate2D, memberLocs: [PlanCoord]) async -> TimeInterval {
//    let results = try? await withThrowingTaskGroup(of: TimeInterval.self) { group in
//        for memberLoc in memberLocs {
//            group.addTask {
//                try await calculateETA(from: memberLoc.kvtoc, to: destination)
//            }
//        }
//
//        var times = [TimeInterval]()
//        for try await eta in group {
//            times.append(eta)
//        }
//
//        return times
//    }
//
//    guard let etas = results, !etas.isEmpty else { return 0 }
//    return etas.reduce(0, +) / Double(etas.count)
//}

struct LocationETAEstimator: Tool {
    let name: String = "estimateLocationETAs"
    let description: String = "Estimate travel time from one location to another using latitude and longitude."
        
    @Generable
    struct Arguments: Codable {
        @Guide(description: "The latitude of the start of the journey", .range(-90...90))
        let fromLatitude: Double

        @Guide(description: "The longitude of the start of the journey", .range(-180...180))
        let fromLongitude: Double

        @Guide(description: "The latitude of the destination", .range(-90...90))
        let toLatitude: Double

        @Guide(description: "The longitude of the destination", .range(-180...180))
        let toLongitude: Double
    }


        func call(arguments: Arguments) async throws -> ToolOutput {
            let fromCoord = CLLocationCoordinate2D(latitude: arguments.fromLatitude, longitude: arguments.fromLongitude)
            let toCoord = CLLocationCoordinate2D(latitude: arguments.toLatitude, longitude: arguments.toLongitude)

            let eta = try await calculateETA(from: fromCoord, to: toCoord)
            return ToolOutput(GeneratedContent(properties: ["ETA": eta]))
        }
}

@Generable
struct LatitudeLongitudeCoordinate {
    var latitude: Double
    var longitude: Double

    var kvtoc: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
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
            }


        func call(arguments: Arguments) async throws -> ToolOutput {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = arguments.query
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: arguments.latitude, longitude: arguments.longitude),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )

            let response = try await MKLocalSearch(request: request).start()

            let results: [PossibleLocation] = response.mapItems.prefix(5).map {
                PossibleLocation(
                    placeType: $0.placemark.title ?? "Unknown",
                    name: $0.name ?? "Unknown",
                    estimatedTimeArrivalSeconds: 0.0,
                    resultLatitude: $0.placemark.coordinate.latitude,
                    resultLongitude: $0.placemark.coordinate.longitude,
                    details: $0.placemark.description
                )
            }

            return ToolOutput(GeneratedContent(results))
        }
    }
//
//extension Result: ConvertibleToGeneratedContent {
//    var generatedContent: GeneratedContent {
//        return GeneratedContent(
//            properties: ["name":name,"subtitle":subtitle,"latitude":Double(coordinate.latitude),"longitude":Double(coordinate.longitude)]
//        )
//    }
//}


struct AddLocationView: View {
    @Binding var event: Event
    @Environment(\.dismiss) private var dismiss
    enum LocationAddMode: String, CaseIterable {
        case search = "Search"
        case ai = "AI Recommend"
    }

    @State private var selectedMode: LocationAddMode = .search

    var body: some View {
        VStack{
            Picker("Choose a method", selection: $selectedMode) {
                ForEach(LocationAddMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            if selectedMode == .search {
//                SearchLocationView(places: $places, onSelect: { location in
//                    // Add location to the plan
//                })
            } else {
                AIRecommendationView(event: $event) { selectedLocation in
                    event.plan.locations.append(selectedLocation)
                    dismiss()
                }
            }
        }
    }
}
