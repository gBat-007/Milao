import SwiftUI
import FoundationModels
import Foundation
import CoreLocation

struct BlinkingImage: View {
    @State private var isVisible = true

    var body: some View {
        Image(systemName: "sparkles") // or any image you want
            .resizable()
            .scaledToFit()
            .frame(width: 25, height: 25)
            .opacity(isVisible ? 1.0 : 0.2)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Models

@Generable
struct PlaceQuestion {
    @Guide(description: "A multiple-choice question about the place.")
    var question: String?

    @Guide(description: "2–4 answer options.", .count(2...4))
    var options: [String]?
    
    @Guide(description: "A short place description based on all user choices.")
    var description: String?
}

@Generable
struct EmojiGenerator {
    @Guide(description: "An emoji representing the place type.")
    var emoji: String
}

// MARK: - Location

func resolveLocationName(from coordinate: CLLocationCoordinate2D?) async -> String {
    guard let coordinate else { return "your area" }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    do {
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks.first?.locality ?? placemarks.first?.name ?? "your area"
    } catch {
        return "your area"
    }
}

//
//// MARK: - SwiftUI View
//
//struct GuidedPlaceCreatorView: View {
//    @Binding var places: [Place]
//    @AppStorage("memberData") private var memberData: Data?
//
//    @State private var placeType: String = ""
//    @State private var locationName: String = ""
//    @State private var currentQuestion: PlaceQuestion?
//    @State private var answers: [String: String] = [:]
//    @State private var emoji: String = ""
//    @State private var description: String = ""
//    @State private var step = 0
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 24) {
//                if step == 0 {
//                    TextField("Type of place (e.g. Restaurant)", text: $placeType)
//                        .textFieldStyle(.roundedBorder)
//
//                    Button("Start") {
//                        Task { await start() }
//                    }
//                    .buttonStyle(.borderedProminent)
//                } else if let q = currentQuestion {
//                    Text(q.question ?? "No Existing Question")
//                        .font(.headline)
//
//                    ForEach(q.options ?? [], id: \.self) { option in
//                        Button(option) {
//                            Task {
//                                answers[q.question ?? ""] = option
//                                await askNext()
//                            }
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                } else {
//                    ProgressView("Thinking...")
//                }
//
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Add Place")
//        }
//    }
//
//    func start() async {
//        guard let member = try? JSONDecoder().decode(Member.self, from: memberData ?? Data()) else { return }
//        locationName = await resolveLocationName(from: member.coordinate)
//
//        do {
//            let session = LanguageModelSession(
//                instructions: "Generate a single character that is an emoji."
//            )
//            
//            let response = try await session.respond(
//                to: "Generate a single character that's an emoji representing the place type \(placeType).",
//                generating: EmojiGenerator.self
//            )
//            
//            emoji = response.content.emoji
//            step = 1
//
//            await askNext()
//
//        } catch {
//            print("Start Error: \(error)")
//        }
//    }
//
//    func askNext() async {
//        do {
//            let session = LanguageModelSession(
//                instructions: "Narrow down the type of place with guided questioning, such as price, contextualised by location. Once narrowed down, generate a final summary."
//            )
//            
//            let response = try await session.respond(
//                to: "Narrow down the type of \(placeType) contextualised for \(locationName) with prior answers of \(answers). Generate question and options if another question is deemed useful, else if narrowed down, simply generate a description and leave question and options empty.",
//                generating: PlaceQuestion.self
//            )
//            
//            if let question = response.content.question {
//                currentQuestion = response.content
//            } else {
//                // No more questions → finalize
//                if let description = response.content.description {
//                    currentQuestion = nil
//                    step = 0
//                    places.append(Place(name: placeType, descriptionAI: description, emoji: emoji))
//                    dismiss()
//                } else {
//                    await askNext()
//                }
//            }
//        } catch {
//            print("AskNext Error: \(error)")
//        }
//    }
//}
//
////struct EmojiTool: Tool {
////    var description: String
////    static var name: String { "generate_emoji" }
////
////    @Generable
////    struct Arguments: Codable, Sendable {
////        var placeType: String
////    }
////
////    func call(arguments: Arguments) async throws -> ToolOutput {
////        let session = LanguageModelSession()
////        let result = try await session.respond(
////            to: "Give one emoji that represents a \(arguments.placeType). Do not explain.",
////            generating: EmojiGenerator.self
////        )
////        
////        let content = GeneratedContent(properties: [
////            "emoji": result.content.emoji
////        ])
////        return ToolOutput(content)
////    }
////}
////
////
////struct QuestionTool: Tool {
////    var description: String = "Generating Questions about Places"
////    static var name: String { "ask_question" }
////
////    @Generable
////    struct Arguments: Codable, Sendable {
////        var placeType: String
////        var location: String
////        var previous: [String: String]
////    }
////
////    func call(arguments: Arguments) async throws -> ToolOutput {
////        let prefs = arguments.previous.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
////        let prompt = """
////        Ask a multiple-choice question (2–5 options) about what kind of \(arguments.placeType) the user wants in \(arguments.location). Prior answers: \(prefs)
////        """
////        let session = LanguageModelSession()
////        let result = try await session.respond(to: prompt, generating: PlaceQuestion.self)
////
////        let content = GeneratedContent(properties: [
////            "question": result.content.question,
////            "options": result.content.options
////        ])
////        return ToolOutput(content)
////    }
////}
////
////
////struct FinalTool: Tool {
////    var description: String = "Generating a final summary of the place once questioning is complete"
////    static var name: String { "finalize_place" }
////
////    @Generable
////    struct Arguments: Codable, Sendable {
////        var placeType: String
////        var location: String
////        var answers: [String: String]
////    }
////
////    func call(arguments: Arguments) async throws -> ToolOutput {
////        let prefs = arguments.answers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
////        let prompt = """
////        Summarize a \(arguments.placeType) in \(arguments.location) with preferences: \(prefs). Return a short, natural-sounding description.
////        """
////        let session = LanguageModelSession()
////        let result = try await session.respond(to: prompt, generating: PlaceDescription.self)
////
////        let content = GeneratedContent(properties: [
////            "description": result.content.description
////        ])
////        return ToolOutput(content)
////    }
////}
