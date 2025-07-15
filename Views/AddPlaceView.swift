import Foundation
import FoundationModels
import SwiftUI

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
                instructions: """
                You are a culturally aware assistant helping a user narrow down their ideal type of \(placeType) in \(locationName). Use a step-by-step questioning approach, asking only highly relevant, high-impact questions based on prior answers and location context.

                Each response must follow one of two *exclusive* formats:

                1. **If another question is needed:**
                   - Provide a clear, specific question in the `question` field.
                   - Provide 2–5 culturally appropriate, well-phrased options in the `options` array.
                   - Leave the `description` field empty.

                2. **If no more questions are needed:**
                   - Leave `question` and `options` completely empty.
                   - Use the `description` field to write a short, vivid, and natural-sounding summary of the kind of place that fits the user's preferences. It should feel like a confident recommendation or refined category.

                Important:
                - Never fill both `description` and `question`/`options` at the same time.
                - Only ask questions that significantly help narrow down preferences.
                - Avoid generic or repetitive questions.
                - Contextualize to the location when relevant (e.g., popular cuisines in Hyderabad).

                Example:
                If the user has already chosen “South Indian” cuisine and “Fast Food,” you probably don’t need to ask about dining type again — just summarize something like:
                > “A budget-friendly, casual South Indian eatery in Hyderabad with dosa and idli as staples.”
                """
            )

            let response = try await session.respond(
                to: """
                The user is looking for a \(placeType) in \(locationName).
                They’ve already answered: \(answers).

                Either:
                - Ask one more highly relevant question to clarify preferences (question + options), OR
                - Summarize the best-fit place based on the current answers (description only).
                Never mix the two.
                """,
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
