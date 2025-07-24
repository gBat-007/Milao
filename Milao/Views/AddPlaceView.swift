import SwiftUI
import FoundationModels

struct AddPlaceView: View {
    @State private var placeType: String = ""
    @State private var emoji: String = ""
    @State private var errorMessage: String?
    @State private var isThinking = false
    @State private var presentAIMode = false
    @State private var presentManualMode = false
    @State private var finalDescription: String?
    @State private var step = 0 // Step 0: enter type, Step 1: choose next action
    @Binding var draftPlace: Place?
    @Binding var color1: CodableColor
    @Binding var color2: CodableColor
    var previousPlace: Place? //if it has a value of Place
    @AppStorage("memberData") private var memberData: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StepProgressView(steps: ["Type", "Details","Location"], currentStep: step)
                    .padding(.horizontal, 30)

                if step == 0 {
                    // Step 1 UI: enter type
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What kind of place are you looking for?")
                            .font(.title3.bold())
                            .padding(.top)
                            .padding(.horizontal)

                        TextField("e.g. Restaurant, Park, Temple", text: $placeType)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                        }

                        Button {
                            Task { await generateEmoji() }
                        } label: {
                            Label("Continue", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(placeType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .glassEffect(.regular.tint(color1.color).interactive())
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                }

                if step == 1 {
                    VStack(spacing: 24) {
                        // 📍 Heading
                        VStack(spacing: 8) {
                            if !emoji.isEmpty {
                                Text("\(placeType)  \(emoji)")
                                    .font(.title)
                                    .bold()
                            }

                            Text("How would you like to describe this place?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 32)
                        .padding(.horizontal)

                        // 🧠 AI Mode Button
                        Button {
                            presentAIMode = true
                        } label: {
                            choiceCard(
                                title: "Answer AI-Guided Questions",
                                subtitle: "Let us help you describe the place step by step.",
                                systemImage: "wand.and.stars"
                            )
                        }
                        .padding(.horizontal)

                        // ✍️ Manual Mode Button
                        Button {
                            presentManualMode = true
                        } label: {
                            choiceCard(
                                title: "Manually Describe It",
                                subtitle: "Type out the description yourself.",
                                systemImage: "pencil"
                            )
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }

                
                if step == 2 {
                    AddLocationView(placeType: placeType, placeDesc: finalDescription ?? "Description Not Available", previousPlace: previousPlace){ loc in
                        finalize(location: loc)
                        dismiss()
                    }
                }
                
                if isThinking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(color2.color)
                        .padding()
                }

                Spacer()
            }
            .sheet(isPresented: $presentAIMode) {
                AIGuidedQuestionView(
                    placeType: placeType,
                    color1: color1,
                    color2: color2
                ) { desc in
                    finalDescription = desc
                    step += 1
                }
            }
            .sheet(isPresented: $presentManualMode) {
                ManualDescriptionView(color1: color1, color2: color2) { desc in
                    finalDescription = desc
                    step += 1
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


    func generateEmoji() async {
        do {
            isThinking = true
            errorMessage = nil
            emoji = ""

            let trimmed = placeType.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let emojiSession = LanguageModelSession(instructions: "Generate a single character that is an emoji.")
            let emojiResponse = try await emojiSession.respond(
                to: "Generate a single character that's an emoji representing the place type \(trimmed).",
                generating: EmojiGenerator.self
            )

            emoji = emojiResponse.content.emoji
            step = 1 // move to next UI step
        } catch {
            errorMessage = "Failed to generate emoji."
        }

        isThinking = false
    }

    func finalize(location: Location) {
        draftPlace = Place(
            id: UUID().uuidString,
            name: placeType,
            descriptionAI: finalDescription ?? "Description Not Available",
            emoji: emoji,
            location: location
        )
    }
    
    @ViewBuilder
    private func choiceCard(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray5))
        )
    }

}
