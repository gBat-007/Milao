import SwiftUI

struct WatchContentView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            List(session.events) { event in
                NavigationLink(destination: WatchEventDetailView(event: event)) {
                    HStack {
                        Text(event.emoji)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                            Text(event.eventDate, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Events")
        }
        .onAppear {
            session.requestEvents()
        }
    }
}
