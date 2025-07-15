//
//  TimeManager.swift
//  Milao
//
//  Created by yash on 15/07/25.
//
import Foundation
import ActivityKit

class TimerManager {
    static let shared = TimerManager()
    
    private var activity: Activity<TimerAttributes>?

    func startTimer(duration: Int) {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(duration))
        
        let attributes = TimerAttributes()
        let state = TimerAttributes.ContentState(startTime: start, endTime: end)

        do {
            activity = try Activity<TimerAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }
    
    func stopTimer() {
        Task {
            if let activity = activity {
                await activity.end(dismissalPolicy: .immediate)
                print("🛑 Live Activity ended")
                self.activity = nil
            } else {
                print("⚠️ No active Live Activity to stop")
            }
        }
    }
}
