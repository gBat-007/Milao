import SwiftUI
import FoundationModels
import Foundation


struct AddPlaceView: View {
    @State private var placeType: String = ""
    @State private var locationName: String = ""
    @State private var currentQuestion: PlaceQuestion.PartiallyGenerated?
    @State private var answers: [String: String] = [:]
    @State private var emoji: String = ""
    @State private var isThinking = false
    @State private var step = 0
    @State private var errorMessage: String?
    
    @Binding var draftPlace: Place?
    @Binding var color1: CodableColor
    @Binding var color2: CodableColor
    @AppStorage("memberData") private var memberData: Data?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if step == 0 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What kind of place are you looking for?")
                            .font(.title3.bold())
                            .padding()
                        
                        TextField("e.g. Restaurant, Park, Temple", text: $placeType)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                        }

                        Button(action: {
                            Task { await start() }
                        }) {
                            Label("Start", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .glassEffect(.regular.tint(color1.color).interactive())
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                        .disabled(placeType.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else if let q = currentQuestion  {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(q.question ?? "Loading...")
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil) // <- unlimited lines
                            .fixedSize(horizontal: false, vertical: true) // <- expand vertically, wrap lines
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(q.options ?? [], id: \.self) { option in
                            Button(action: {
                                Task {
                                    answers[q.question ?? ""] = option
                                    await askNext()
                                }
                            }) {
                                Text(option)
                                    .frame(maxWidth: .infinity)
                            }
                            .glassEffect(.regular.tint(color1.color).interactive())
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                    }
                }

                else if isThinking {
                    VStack{
                        BlinkingImage()
                            .padding(20)
                            .tint(color2.color)
                        Text("Thinking...")
                            .fontDesign(.rounded)
                    }
                    
                }

                Spacer()
            }
            .padding(.top, 40)
            .animation(.easeInOut, value: isThinking)
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    
    func start() async {
        do {
            placeType = placeType.trimmingCharacters(in: .whitespacesAndNewlines)
            
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
            They’ve already answered: \(answers).
            Summarize the type of place the user wants based on the current answers (description only). Do NOT give an exact location or specific place, just the requirements & preferences should be summarised. Do NOT generate 'question' or options; leave them fully empty.
            """
            : """
            The user is looking for a \(placeType) in \(locationName).
            They’ve already answered: \(answers).
            - Ask one more highly relevant question to clarify preferences (question + options), OR
            - Summarize the type of place based on the current answers (description only).
            Never mix the two. Do NOT generate 'question' and 'options' if not necessary or if 7 questions have been asked.
            """
            
            let stream = session.streamResponse(to: prompt, generating: PlaceQuestion.self)
            
            for try await partial in stream {
                self.currentQuestion = partial // could also update live here if needed
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
                
                draftPlace = Place(id: UUID().uuidString, name: placeType, descriptionAI: desc, emoji: emoji)
                dismiss()
            } else {
                await askNext() // retry if invalid
            }
            
        } catch {
            errorMessage = "Failed to generate more information."
            print("AskNext Error: \(error)")
        }
        
        step += 1
    }
}
