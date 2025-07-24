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
                    Text("Event: \(context.state.title)")
                    HStack {
                        Text("Starts in: ")
                        timerLabel(context: context)
                            .frame(minWidth: 40, maxWidth: 100, alignment: .trailing)
                    }
                }
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        HStack(spacing: 6) {
                            Image(uiImage: UIImage(named: "milaoapp") ?? UIImage()) // App icon
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            Text("Milao") // App name
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 9)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .center) {
                            Text(context.state.emoji)
                                .font(.system(size: 48))
                                .frame(alignment: .leading)
                        }
                        HStack(alignment: .center) {
                            Divider()
                                    .frame(height: 50) // vertical height
                                    .frame(width: 1)   // thin line
                                    .background(Color.gray)
                        }
                        Spacer()
                        VStack {
                            HStack {
                                Spacer()
                                Text("Event: \(context.state.title)")
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                Spacer()
                                Text("Starts in:")
                                if context.state.endTime.timeIntervalSince(context.state.startTime) > 3600 {
                                       timerLabel(context: context)
                                                .frame(width: 75, alignment: .leading)
                                } else {
                                timerLabel(context: context)
                                                .frame(width: 55, alignment: .leading)
                                }
                                Spacer()
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                }
            } compactLeading: {
                Text(context.state.emoji)
            } compactTrailing: {
                if context.state.endTime.timeIntervalSince(context.state.startTime) > 3600 {
                       timerLabel(context: context)
                                .frame(width: 65, alignment: .leading)
                } else {
                timerLabel(context: context)
                                .frame(width: 45, alignment: .leading)
                }
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
