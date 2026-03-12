import SwiftUI

struct SuggestionCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(WIXTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .padding(20)
            .background(WIXTheme.panel, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
