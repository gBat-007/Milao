import SwiftUI

struct StepProgressView: View {
    let steps: [String]            // Step labels like ["Type", "Details"]
    let currentStep: Int           // Starts at 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 0) {
                    // Step circle
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 28, height: 28)
                            
                            Text("\(index + 1)")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        
                        Text(steps[index])
                            .font(.caption2)
                            .foregroundColor(index <= currentStep ? .blue : .gray)
                    }
                    
                    // Connecting line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(.top)
    }
}
