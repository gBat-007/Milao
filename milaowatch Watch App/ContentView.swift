import SwiftUI

struct WatchContentView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            List(session.events) { event in
                NavigationLink(destination: WatchEventDetailView(event: $event)) {
                    WatchEventRow(event: $event)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(event.colorGradient)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .blur(radius: 0.3) // small blur for softness
                        .padding(.vertical, 2)
                }
            }
            .navigationTitle("Events")
        }
        .onAppear {
            print("👀 WatchContentView appeared — requesting events")
            WatchSessionManager.shared.requestEvents()
        }
    }
}

struct WatchEventRow: View {
    @Binding var event: WidgetEvent
    @State var textColor: Color = .black
    @State var subTextColor: Color = .gray
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(5)
            .cornerRadius(10)
        }
        .onAppear {
            let isDarkBG = event.bgColor1.color.isDark && event.bgColor2.color.isDark
            textColor = isDarkBG ? .white : .black
            subTextColor = isDarkBG ? .white.opacity(0.8) : .black.opacity(0.6)
        }
    }
    
    #Preview {
        ContentView()
    }
}
