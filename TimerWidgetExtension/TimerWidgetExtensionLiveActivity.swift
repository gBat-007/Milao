//
//  TimerWidgetExtensionLiveActivity.swift
//  TimerWidgetExtension
//
//  Created by yash on 15/07/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimerWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TimerWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimerWidgetExtensionAttributes {
    fileprivate static var preview: TimerWidgetExtensionAttributes {
        TimerWidgetExtensionAttributes(name: "World")
    }
}

extension TimerWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: TimerWidgetExtensionAttributes.ContentState {
        TimerWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimerWidgetExtensionAttributes.ContentState {
         TimerWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TimerWidgetExtensionAttributes.preview) {
   TimerWidgetExtensionLiveActivity()
} contentStates: {
    TimerWidgetExtensionAttributes.ContentState.smiley
    TimerWidgetExtensionAttributes.ContentState.starEyes
}
