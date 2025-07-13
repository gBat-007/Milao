
import SwiftUI
import Foundation
import FoundationModels

@Generable
struct EmojiGenerator {
    @Guide(description: "An emoji that represents the type of place.")
    var emoji: String
}

@Observable
class PlaceGenerator {
    let session = LanguageModelSession()

    func generateEmoji(for placeType: String) async throws -> String {
        let result = try await session.respond(
            to: "Give me only one emoji that represents a \(placeType). Do not include any explanation.",
            generating: EmojiGenerator.self
        )
        return result.content.emoji
    }
}

struct AddPlaceView: View {
    @State private var name: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String?
    
    let placeGenerator = PlaceGenerator()
    var onComplete: (Place) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Type of place (e.g. Restaurant)", text: $name)
                    .textFieldStyle(.roundedBorder)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(isLoading ? "Generating..." : "Generate") {
                    Task {
                        isLoading = true
                        do {
                            let emoji = try await placeGenerator.generateEmoji(for: name)
                            let newPlace = Place(name: name, descriptionAI: "", emoji: emoji)
                            onComplete(newPlace)
                            dismiss()
                        } catch {
                            errorMessage = "Something went wrong. Please try again."
                            print("Error: \(error)")
                        }
                        isLoading = false
                    }
                }
                .disabled(name.isEmpty || isLoading)
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Add Place")
        }
    }
}


import SwiftUI

struct PlacesTab: View {
    @Binding var places: [Place]
    @Binding var presentAddPlaceSheet: Bool

    var body: some View {
        VStack {
            List($places) { $place in
                PlaceRow(place: $place)
                    .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddPlaceSheet) {
            AddPlaceView { newPlace in
                places.append(newPlace)
            }
            .presentationDetents([.medium])
        }
    }
}


struct PlaceRow: View {
    @Binding var place: Place
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(place.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(place.descriptionAI)
                        .font(.subheadline)
//                    HStack(spacing: 12) {
//                        Label("\(event.membersNum)", systemImage: "person.3.fill")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                        
//                        Label("\(event.locationsNum)", systemImage: "mappin.and.ellipse")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                    }
                }
                Spacer()
            }
            .padding(10)
            .cornerRadius(12)
        }
    }
    
}
