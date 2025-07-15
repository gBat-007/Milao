//
//  TimerAttributes.swift
//  Milao
//
//  Created by yash on 15/07/25.
//
import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
    }
}
