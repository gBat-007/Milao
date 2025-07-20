//
//  CountDownView.swift
//  Milao
//
//  Created by yash on 19/07/25.
//
import SwiftUI
import Combine

struct CountdownView: View {
    let to: Date
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formattedTimeRemaining())
            .monospacedDigit()
            .onReceive(timer) { current in
                if current >= to {
                    now = to
                } else {
                    now = current
                }
            }
    }

    func formattedTimeRemaining() -> String {
        let remaining = Int(to.timeIntervalSince(now))
        if remaining <= 0 { return "00:00" }

        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

