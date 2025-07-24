//
//  AddEventOption.swift
//  Milao
//
//  Created by Gautam Bansal on 24/07/25.
//

import SwiftUI

struct AddEventOption: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            .shadow(radius: 1)
        }
    }
}
