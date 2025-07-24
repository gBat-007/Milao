import SwiftUI

struct StepProgressView: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                index < currentStep
                                    ? AnyShapeStyle(Color.green.opacity(0.8))
                                    : index == currentStep
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                        : AnyShapeStyle(Color.gray.opacity(0.3))
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: index == currentStep ? .blue.opacity(0.4) : .clear, radius: 4)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        } else {
                            Text("\(index + 1)")
                                .foregroundColor(.white)
                                .font(.footnote.bold())
                        }
                    }

                    Text(steps[index])
                        .font(.caption)
                        .foregroundColor(index <= currentStep ? .primary : .gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 60)
                }
                .frame(maxWidth: .infinity)

                if index < steps.count - 1 {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(index < currentStep ? Color.green.opacity(0.8) : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .offset(y: 14) // Vertically center between circles (32 height)
                    }
                    .frame(height: 32)
                }
            }
        }
        .padding()
    }
}
