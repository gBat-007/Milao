import SwiftUI

struct WatchContentView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            List(session.events) { event in
                Text(event.title) // basic, for now
            }
            .navigationTitle("Events")
        }
        .onAppear {
            print("👀 WatchContentView appeared — requesting events")
            WatchSessionManager.shared.requestEvents()
        }
    }
}
