import SwiftUI
import UIKit

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 46)
            } else {
                Spacer(minLength: 46)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(message.role == .assistant ? "WIX!" : "You")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)

                Text(timestampText)
                    .font(.caption2)
                    .foregroundStyle(WIXTheme.textMuted)
            }

            if !message.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(message.attachments) { attachment in
                            AttachmentPreviewCard(attachment: attachment)
                        }
                    }
                }
            }

            if !message.text.isEmpty {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            if message.isStreaming {
                StreamingDotsView()
            }
        }
        .padding(16)
        .frame(maxWidth: 340, alignment: .leading)
        .background(message.role == .user ? WIXTheme.bubbleUser : WIXTheme.bubbleAssistant)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contextMenu {
            if !message.text.isEmpty {
                Button {
                    UIPasteboard.general.string = message.text
                    Haptics.tap()
                } label: {
                    Label("Kopioi teksti", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var timestampText: String {
        MessageBubbleView.timeFormatter.string(from: message.createdAt)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct AttachmentPreviewCard: View {
    let attachment: StoredAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if attachment.kind == .image,
               let image = UIImage(contentsOfFile: attachment.localPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 132, height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 132, height: 90)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }

            Text(attachment.fileName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(attachment.formattedSize)
                .font(.caption2)
                .foregroundStyle(WIXTheme.textSecondary)
        }
        .frame(width: 132, alignment: .leading)
    }
}

private struct StreamingDotsView: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index == phase ? 1 : 0.32))
                    .frame(width: 7, height: 7)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(240))
                phase = (phase + 1) % 3
            }
        }
    }
}
