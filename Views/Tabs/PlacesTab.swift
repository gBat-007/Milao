
import SwiftUI
import Foundation
import FoundationModels

struct AddPlaceView: View {
    @State private var placeType: String = ""
    @State private var locationName: String = ""
    @State private var currentQuestion: PlaceQuestion?
    @State private var answers: [String: String] = [:]
    @State private var emoji: String = ""
    @State private var isThinking = false
    @State private var step = 0
    @State private var errorMessage: String?
    
    @AppStorage("memberData") private var memberData: Data?
    @Environment(\.dismiss) private var dismiss

    var onComplete: (Place) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if step == 0 {
                    TextField("Type of place (e.g. Restaurant)", text: $placeType)
                        .textFieldStyle(.roundedBorder)

                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                    }

                    Button("Start") {
                        Task { await start() }
                    }
                    .disabled(placeType.isEmpty)
                    .buttonStyle(.borderedProminent)
                } else if let q = currentQuestion {
                    Text(q.question ?? "No Existing Question")
                        .font(.headline)

                    ForEach(q.options ?? [], id: \.self) { option in
                        Button(option) {
                            Task {
                                answers[q.question ?? ""] = option
                                await askNext()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if isThinking {
                    ProgressView("Thinking...")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add Place")
        }
    }

    func start() async {
        do {
            guard let member = try? JSONDecoder().decode(Member.self, from: memberData ?? Data()) else {
                errorMessage = "Couldn't load your member info."
                return
            }

            locationName = await resolveLocationName(from: member.coordinate)
            step = 1
            isThinking = true

            let emojiSession = LanguageModelSession(instructions: "Generate a single character that is an emoji.")
            let emojiResponse = try await emojiSession.respond(
                to: "Generate a single character that's an emoji representing the place type \(placeType).",
                generating: EmojiGenerator.self
            )
            emoji = emojiResponse.content.emoji
            isThinking = false

            await askNext()

        } catch {
            errorMessage = "Something went wrong. Please try again."
            print("Start Error: \(error)")
        }
    }

    func askNext() async {
        isThinking = true
        do {
            let session = LanguageModelSession(
                instructions: "Narrow down the type of place with guided questioning, such as price, contextualised by location. Once narrowed down, generate a final summary."
            )

            let response = try await session.respond(
                to: "Narrow down the type of \(placeType) contextualised for \(locationName) with prior answers of \(answers). Generate question and options if another question is deemed useful, else if narrowed down, simply generate a description and leave question and options empty.",
                generating: PlaceQuestion.self
            )

            if let question = response.content.question {
                currentQuestion = response.content
            } else if let desc = response.content.description {
                // Done!
                currentQuestion = nil
                isThinking = false
                step = 0

                let newPlace = Place(name: placeType, descriptionAI: desc, emoji: emoji)
                onComplete(newPlace)
                dismiss()
            } else {
                // Retry if no question or description
                await askNext()
            }

        } catch {
            errorMessage = "Failed to generate more information."
            print("AskNext Error: \(error)")
        }
        isThinking = false
    }
}


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
