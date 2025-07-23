import SwiftUI

extension Color {
    var isDark: Bool {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Perceived brightness algorithm
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 0.5
    }
}

struct WatchContentView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            List(session.events) { event in
                NavigationLink(destination: WatchEventDetailView(event: event)) {
                    WatchEventRow(event: event)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [event.bgColor1.color, event.bgColor2.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
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
    var event: WidgetEvent
    @State var textColor: Color = .black
    @State var subTextColor: Color = .gray
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.title)
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
        WatchContentView()
    }
}
