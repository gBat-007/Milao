//
//  ManualDescriptionView.swift
//  Milao
//
//  Created by Gautam Bansal on 23/07/25.
//

import SwiftUI

struct ManualDescriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var descriptionText: String = ""
    var color1: CodableColor
    var color2: CodableColor
    var onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Describe the place you're imagining:")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $descriptionText)
                    .frame(height: 200)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))

                Button("Done") {
                    let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onComplete(trimmed)
                        dismiss()
                    }
                }
                .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .glassEffect(.regular.tint(color1.color).interactive())
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Describe Place")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

