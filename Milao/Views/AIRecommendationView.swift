import SwiftUI
import MapKit
import FoundationModels

@Generable
struct PossibleLocations {
    @Guide(description: "A list of possible locations")
    let locations: [PossibleLocation]
}

@Generable
struct PossibleLocation {
//    @Guide(description: "The place category, like 'restaurant' or 'hotel'.")
    var placeType: String

//    @Guide(description: "The place name, such as a business or landmark.")
    var name: String

//    @Guide(description: "Estimated travel time in seconds.")
    var estimatedTimeArrivalSeconds: TimeInterval

    @Guide(description: "Latitude of the destination.", .range(-90...90))
    var resultLatitude: Double

    @Guide(description: "Longitude of the destination.", .range(-180...180))
    var resultLongitude: Double

//    @Guide(description: "Extra info")
    var details: String
}


import SwiftUI
import MapKit
import FoundationModels

// MARK: - View

struct AIRecommendationView: View {
    @Binding var event: Event
    let onSelect: (Location) -> Void

    @State private var locations: [PossibleLocation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("memberData") private var memberData: Data?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView("Finding recommendations...")
                    .padding()
            } else if let err = errorMessage {
                Text("⚠️ \(err)")
                    .foregroundColor(.red)
                    .padding()
            } else if locations.isEmpty {
                Text("No suggestions found.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(locations.indices, id: \.self) { i in
                    let loc = locations[i]
                    Button {
                        onSelect(Location(
                            id: UUID().uuidString,
                            name: loc.name,
                            coordinate: Coordinate(latitude: loc.resultLatitude, longitude: loc.resultLongitude),
                            ofPlace: event.places[event.plan.locations.count]
                        ))
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loc.name).font(.headline)
                            Text(loc.details).font(.subheadline)
                            Text("ETA: \(formattedETA(loc.estimatedTimeArrivalSeconds))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(.top)
        .onAppear {
            Task { await fetchRecommendations() }
        }
    }

    // MARK: - Data Flow
    
    func fetchRecommendations() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            // 🔁 Session with Tool usage
            let recommendationSession = LanguageModelSession(
                tools: [LocationSearchTool(), LocationETAEstimator()],
                instructions: """
Find real locations close to the provided location using the "searchNearbyLocations" and "estimateLocationETAs" tools.
Return: name, description, coordinates, and ETA. ETA must always exceed 1 minute.
"""

            )
            var planIndex = 0
            if !event.plan.locations.isEmpty {
                planIndex = event.plan.locations.count
            }
            guard let themePlace = event.places[safe: planIndex] ?? event.places.first else {
                errorMessage = "Missing theme."
                return
            }
            guard let member = Member.decode(from: memberData),
                  let coord = member.coordinate else {
                errorMessage = "No member location available"
                return
            }


                        let prompt = """
            Find 5 real-world places for this theme: "\(themePlace.name)" — "\(themePlace.descriptionAI)".
                        Use the tools to:
                        1. Search for real locations.
                        2. Estimate travel time.
                        
                        Use the provided tools including "searchNearbyLocations" to find a real place matching the given descriptions near this location: (latitude: \(coord.latitude), longitude: \(coord.longitude)). Should be within 2 degrees latitude and 2 degrees longitude. Then use "estimateLocationETAs" to find the ETA of each location you find.
                        Return results only after using the tools. Do NOT guess names or coordinates.
            """


            let response = try await recommendationSession.respond(
                to: prompt,
                generating: PossibleLocations.self
            )

            locations = response.content.locations

        } catch LanguageModelSession.GenerationError.guardrailViolation(let ctx) {
            errorMessage = "Guardrail block: \(ctx.debugDescription)"
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
        }
    }


    func formattedETA(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        return "\(minutes) min"
    }
}

extension Collection {
    subscript(safe idx: Index) -> Element? {
        return indices.contains(idx) ? self[idx] : nil
    }
}

@Generable
struct SimpleTextResponse: Codable {
    let text: String
}
