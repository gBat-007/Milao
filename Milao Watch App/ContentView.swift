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
            List {
                Section {
                    ForEach(session.events) { event in
                        NavigationLink(destination: WatchEventDetailView(event: event)) {
                            WatchEventRow(event: event)
                                .padding(0)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [event.bgColor1.color, event.bgColor2.color],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )
                                .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Button(action: {
                        WatchSessionManager.shared.requestEvents()
                    }) {
                        Text("Refresh Events")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }
            }
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
            HStack(alignment: .center, spacing: 16) {
                Text(event.emoji)
                    .font(.title)
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
