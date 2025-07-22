//
//  TimeManager.swift
//  Milao
//
//  Created by yash on 15/07/25.
//
import Foundation
import ActivityKit

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
        var emoji: String
        var title: String
    }
}

struct WidgetEvent: Codable, Hashable, Identifiable{
    var id: String
    var title: String
    var emoji: String
    var eventDate: Date
    var memberCount: Int
    var placesNum: Int
    var bgColor1: CodableColor
    var bgColor2: CodableColor
    
}

class TimerManager {
    static let shared = TimerManager()
    private var activity: Activity<TimerAttributes>?
    
    func stopAllLiveActivities() {
            Task {
                for activity in Activity<TimerAttributes>.activities {
                    await activity.end(dismissalPolicy: .immediate)
                    print("🛑 Ended Live Activity: \(activity.id)")
                }
            }
        }
    
    func startSimpleTimer(to widgetEvent: WidgetEvent) {
        let start = Date()
        let end = widgetEvent.eventDate

        let attributes = TimerAttributes()
        let state = TimerAttributes.ContentState(
            startTime: start,
            endTime: end,
            emoji: widgetEvent.emoji,
            title: widgetEvent.title
        )

        do {
            activity = try Activity<TimerAttributes>.request(attributes: attributes, contentState: state)
            print("✅ Timer started until \(end)")
//            scheduleAutoEnd(at: end)
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    private func scheduleAutoEnd(at endTime: Date) {
        let delay = endTime.timeIntervalSinceNow
        guard delay > 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Task {
                if let activity = self.activity {
                    await activity.end(dismissalPolicy: .immediate)
                    self.activity = nil
                    print("🛑 Live Activity ended")
                }
            }
        }
    }
}

