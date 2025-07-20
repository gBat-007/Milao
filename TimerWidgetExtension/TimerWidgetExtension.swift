import WidgetKit
import SwiftUI
import ActivityKit
import Foundation

@main
struct TimerWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // Lock Screen view
            HStack {
                Text(context.state.emoji)
                    .font(.largeTitle)
                VStack {
                    Text("Your Event: \(context.state.title)")
                    HStack {
                        Text("Starts in: ")
                        timerLabel(context: context) // ✅
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.trailing) {
                        HStack(spacing: 6) {
                            Image(uiImage: UIImage(named: "milaoapp") ?? UIImage()) // App icon
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text("Milao") // App name
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.emoji)
                            .font(.largeTitle)
                        VStack {
                            Text("Your Event: \(context.state.title)")
                            HStack {
                                Text("Starts in: ")
                                timerLabel(context: context) // ✅
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
            } compactLeading: {
                Text(context.state.emoji)
            } compactTrailing: {
                timerLabel(context: context)
                    .frame(width: 40, alignment: .trailing)
            } minimal: {
                Text(context.state.emoji)
            }
        }
    }

    func timerLabel(context: ActivityViewContext<TimerAttributes>) -> some View {
        Text(
            timerInterval: context.state.startTime...context.state.endTime,
            countsDown: true
        )
        .monospacedDigit()
    }
}
