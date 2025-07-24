//
//  AlarmKitLiveActivity.swift
//  AlarmKit
//
//  Created by yash on 24/07/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AlarmKitAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AlarmKitLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmKitAttributes.self) { context in
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

extension AlarmKitAttributes {
    fileprivate static var preview: AlarmKitAttributes {
        AlarmKitAttributes(name: "World")
    }
}

extension AlarmKitAttributes.ContentState {
    fileprivate static var smiley: AlarmKitAttributes.ContentState {
        AlarmKitAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AlarmKitAttributes.ContentState {
         AlarmKitAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AlarmKitAttributes.preview) {
   AlarmKitLiveActivity()
} contentStates: {
    AlarmKitAttributes.ContentState.smiley
    AlarmKitAttributes.ContentState.starEyes
}
