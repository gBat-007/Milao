import WidgetKit
import SwiftUI
import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
    }
}

@main
struct TimerWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // Lock Screen & Banner UI
            VStack {
                Text("TITLE Live Activity")
                Text("BELOWTITLE Live Activity")
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text("TEST")
                        Text("If u see this, u have expanded the island")
                    }
                }
            } compactLeading: {
                Text("🤫🧏‍♂️")
            } compactTrailing: {
                Text("🤪")
            } minimal: {
                Text("T4")
            }
        }
    }
}
