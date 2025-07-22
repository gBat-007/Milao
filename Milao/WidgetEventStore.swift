import Foundation
internal import Combine

class WidgetEventStore: ObservableObject {
    static let shared = WidgetEventStore()
    
    @Published var widgetEvents: [WidgetEvent] = []
    
    private init() {}
}
