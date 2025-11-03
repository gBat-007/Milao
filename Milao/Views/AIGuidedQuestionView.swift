import SwiftUI
import FoundationModels
import Foundation


struct AIGuidedQuestionView: View {
    var placeType: String
    var color1: CodableColor
    var color2: CodableColor
    var onComplete: (String) -> Void

    @State private var currentQuestion: PlaceQuestion.PartiallyGenerated?
    @State private var answers: [String: String] = [:]
    @State private var emoji: String = ""
    @State private var isThinking = false
    @State private var step = 0
    @State private var errorMessage: String?

    @AppStorage("memberData") private var memberData: Data?
    @Environment(\.dismiss) private var dismiss

    @State private var locationName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let q = currentQuestion {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Question
                            Text(q.question ?? "Loading...")
                                .font(.title3.weight(.semibold))
                                .multilineTextAlignment(.leading)
                                .padding(.top, 24)
                                .padding(.horizontal)
                                .transition(.opacity)

                            // Options
                            VStack(spacing: 16) {
                                ForEach(q.options ?? [], id: \.self) { option in
                                    Button(action: {
                                        Task {
                                            answers[q.question ?? ""] = option
                                            await askNext()
                                        }
                                    }) {
                                        Text(option)
                                            .font(.body.weight(.medium))
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                    }
                                    .glassEffect(.regular.tint(color1.color).interactive())
                                    .buttonStyle(.borderedProminent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 20)
                                }
                            }

                            Spacer(minLength: 60)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                } else if isThinking {
                    VStack {
                        BlinkingImage()
                            .padding(20)
                            .tint(color2.color)
                        Text("Thinking...")
                            .fontDesign(.rounded)
                    }

                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding(.top, 40)
            .animation(.easeInOut, value: isThinking)
            .navigationTitle("Guided Questions")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await start()
            }
        }
    }

    func start() async {
        do {
            currentQuestion = nil
            answers = [:]
            emoji = ""
            isThinking = true
            errorMessage = nil

            guard let member = try? JSONDecoder().decode(Member.self, from: memberData ?? Data()) else {
                errorMessage = "Couldn't load your member info."
                return
            }

            locationName = await resolveLocationName(from: member.coordinate)

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
        defer { isThinking = false }

        do {
            let session = LanguageModelSession(
                instructions: """
                You are a culturally aware assistant helping a user narrow down their ideal type of \(placeType) in \(locationName). Use a step-by-step questioning approach, asking only highly relevant, high-impact questions based on prior answers and location context.

                Each response must follow one of two *exclusive* formats:

                1. **If another question is needed:**
                   - Provide a clear, specific question in the `question` field.
                   - Provide 2–4 culturally appropriate, well-phrased options in the `options` array.
                   - Leave the `description` field empty.

                2. **If no more questions are needed:**
                   - Leave `question` and `options` completely empty.
                   - Use the `description` field to write a short, vivid, and natural-sounding summary of the kind of place that fits the user's preferences. It should feel like a confident recommendation or refined category.

                Important:
                - Never fill both `description` and `question`/`options` at the same time.
                - Only ask questions that significantly help narrow down preferences.
                - Avoid generic or repetitive questions.
                - Contextualize to the location when relevant (e.g., popular cuisines in Hyderabad).

                ALWAYS ASK necessary questions such as dietary requirements first.

                You are to ask a maximum of 5 follow-up questions and then generate a 'description' by keeping both `question` and `options` empty.
                """
            )

            let prompt = step >= 5
            ? """
            The user is looking for a \(placeType) in \(locationName).
            They've already answered: \(answers).
            Summarize the type of place the user wants based on the current answers (description only). Do NOT give an exact location or specific place, just the requirements & preferences should be summarised. Do NOT generate 'question' or options; leave them fully empty.
            """
            : """
            The user is looking for a \(placeType) in \(locationName).
            They've already answered: \(answers).
            - Ask one more highly relevant question to clarify preferences (question + options), OR
            - Summarize the type of place based on the current answers (description only).
            Never mix the two. Do NOT generate 'question' and 'options' if not necessary or if 7 questions have been asked.
            """

            // Fixed: Correct streamResponse syntax
            let stream = try await session.streamResponse(generating: PlaceQuestion.self) {
                prompt
            }

            for try await partial in stream {
                self.currentQuestion = partial.content
            }

            guard let response = currentQuestion else {
                errorMessage = "No response received."
                return
            }

            if let question = response.question?.trimmingCharacters(in: .whitespacesAndNewlines), !question.isEmpty {
                if response.options?.count ?? 0 > 0 {
                    currentQuestion = response
                } else {
                    await askNext()
                }
            } else if let desc = response.description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty, step >= 2 {
                currentQuestion = nil
                step = 0

                onComplete(desc)
                dismiss()
            } else {
                await askNext()
            }

        } catch {
            errorMessage = "Failed to generate more information."
            print("AskNext Error: \(error)")
        }

        step += 1
    }

}
