import AlarmKit

nonisolated struct EventAlarmMetadata: AlarmMetadata, Codable, Hashable, Sendable {
    var id: String
    var title: String
    var emoji: String
}
