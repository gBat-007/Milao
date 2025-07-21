import SwiftUI

struct WidgetEvent: Codable, Hashable, Identifiable{
    var id: String
    var title: String
    var emoji: String
    var eventDate: Date
    var memberCount: Int
    var placesNum: Int
}

struct WatchEventDetailView: View {
    let event: WidgetEvent

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(event.emoji)
                    .font(.system(size: 50))

                Text(event.title)
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Text(event.eventDate, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Divider()

                HStack {
                    Label("\(event.memberCount)", systemImage: "person.3.fill")
                    Label("\(event.placesNum)", systemImage: "mappin.and.ellipse")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Details")
    }
}
