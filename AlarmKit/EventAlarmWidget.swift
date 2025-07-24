import SwiftUI
import WidgetKit
import ActivityKit
import AlarmKit

struct EventAlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<EventAlarmMetadata>.self) { _ in
            EmptyView() // System uses this for Lock Screen / StandBy
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}
