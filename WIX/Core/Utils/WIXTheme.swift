import SwiftUI

enum WIXTheme {
    static let background = Color.black
    static let panel = Color.white.opacity(0.07)
    static let panelStrong = Color.white.opacity(0.10)
    static let border = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textMuted = Color.white.opacity(0.42)
    static let bubbleUser = Color.white.opacity(0.11)
    static let bubbleAssistant = Color.white.opacity(0.06)
}

struct WIXBackdrop: View {
    var body: some View {
        ZStack {
            WIXTheme.background

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: -120, y: -280)

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 130, y: 240)

            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.02), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
