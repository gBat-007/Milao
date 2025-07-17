import SwiftUI
import MapKit
import FoundationModels

@Generable
struct PossibleLocations {
    @Guide(description: "A list of potential real locations, each with details like type, name, ETA, and coordinates.")
    let locations: [PossibleLocation]
}

@Generable
struct PossibleLocation {
    @Guide(description: "The type of place, such as 'restaurant', 'hotel', 'theater', or 'park'.")
    var placeType: String

    @Guide(description: "The name of the location, typically a business or landmark name.")
    var name: String

    @Guide(description: "The estimated time it would take to travel to this location, in seconds.")
    var eta: TimeInterval

    @Guide(description: "The latitude coordinate of the potential destination.", .range(-90...90))
    var latitude: Double

    @Guide(description: "The longitude coordinate of the potential destination.", .range(-180...180))
    var longitude: Double

    @Guide(description: "A descriptive summary of the place, which could include its address, features, or notable context.")
    var description: String
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
                            coordinate: Coordinate(latitude: loc.latitude, longitude: loc.longitude),
                            ofPlace: event.places[event.plan.locations.count]
                        ))
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loc.name).font(.headline)
                            Text(loc.description).font(.subheadline)
                            Text("ETA: \(formattedETA(loc.eta))")
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
            
            Use the provided tools including "searchNearbyLocations" to find a real place matching the given descriptions near this location: (latitude: \(coord.latitude), longitude: \(coord.longitude)). Then use "estimateLocationETAs" to find the ETA of each location you find.
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
