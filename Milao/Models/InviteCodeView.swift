import SwiftUI

struct InviteCodeView: View {
    let inviteCode: String
    @State private var showCopiedToast = false

    var body: some View {
        Text(inviteCode)
            .font(.system(.body, design: .monospaced))
            .bold()
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = inviteCode
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            .onTapGesture {
                UIPasteboard.general.string = inviteCode
                showCopiedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showCopiedToast = false
                }
            }
            .overlay(alignment: .leading) {
                if showCopiedToast {
                    Label("Copied!", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding(.leading, -30)
                }
            }
            .animation(.easeInOut, value: showCopiedToast)
    }
}
