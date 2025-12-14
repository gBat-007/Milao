import SwiftUI

// Put this near SettingsTab in the same file or another Swift file

struct LiveAlarmsListView: View {
    @State private var alarms: [CachedAlarm] = []
    private let cache = AlarmCacheManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(liveAlarms, id: \.eventID) { alarm in
                AlarmTileRow(alarm: alarm) {
                    deleteAlarm(for: alarm.eventID)
                }
            }

            if liveAlarms.isEmpty {
                Text("No active alarms")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .onAppear(perform: loadAlarms)
    }

    private var liveAlarms: [CachedAlarm] {
        alarms
            .filter { $0.isActive && $0.alarmDate > Date() }
            .sorted { $0.alarmDate < $1.alarmDate }
    }

    private func loadAlarms() {
        alarms = cache.cachedAlarms
    }

    private func deleteAlarm(for eventID: String) {
        cache.removeAlarm(eventID: eventID)
        loadAlarms()
        // If you later track AlarmKit UUID per event, cancel it here too.
    }
}

struct AlarmTileRow: View {
    let alarm: CachedAlarm
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.eventName)
                        .font(.headline)

                    Text("ID: \(alarm.eventID)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(alarm.alarmDate.formatted(date: .numeric, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "alarm.fill")
                    .foregroundColor(.orange)
            }
            .padding()
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Alarm", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
