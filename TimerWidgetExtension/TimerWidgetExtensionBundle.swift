//
//  TimerWidgetExtensionBundle.swift
//  TimerWidgetExtension
//
//  Created by yash on 15/07/25.
//

import WidgetKit
import SwiftUI

struct TimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimerWidgetExtension()
        TimerWidgetExtensionControl()
        TimerWidgetExtensionLiveActivity()
    }
}
