import SwiftUI

struct ManualDescriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var descriptionText: String = ""
    var color1: CodableColor
    var color2: CodableColor
    var onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Describe the place you're imagining:")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    Text("Example: An Italian restaurant with vegetarian options including pizza and spinach ravioli")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, -8)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(radius: 1)

                        TextEditor(text: $descriptionText)
                            .padding(12)
                            .frame(minHeight: 200)
                            .background(Color.clear)
                    }
                    .padding(.horizontal)

                    Button {
                        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onComplete(trimmed)
                            dismiss()
                        }
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(color1.color)
                                    .opacity(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                            )
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .padding(.bottom, 8)
            .navigationTitle("Describe Place")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
