import SwiftUI

struct ComposerBar: View {
    @Binding var text: String
    @Binding var mode: ResponseMode
    let attachments: [StoredAttachment]
    let isStreaming: Bool
    let canSend: Bool
    let onPlusTapped: () -> Void
    let onMicTapped: () -> Void
    let onRemoveAttachment: (StoredAttachment) -> Void
    let onSend: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Button(action: onPlusTapped) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Menu {
                        ForEach(ResponseMode.allCases) { option in
                            Button {
                                mode = option
                                Haptics.tap()
                            } label: {
                                Label(option.title, systemImage: option.symbolName)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.symbolName)
                            Text(mode.title)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    Spacer()
                }

                if !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(attachments) { attachment in
                                attachmentChip(for: attachment)
                            }
                        }
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Kysy mitä tahansa", text: $text, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .lineLimit(1...6)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(.white)

                    Button(action: onMicTapped) {
                        Image(systemName: "mic")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(WIXTheme.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: isStreaming ? onStop : onSend) {
                        Image(systemName: isStreaming ? "stop.fill" : "waveform")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 48, height: 48)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .opacity(canSend || isStreaming ? 1 : 0.45)
                    .disabled(!(canSend || isStreaming))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func attachmentChip(for attachment: StoredAttachment) -> some View {
        HStack(spacing: 8) {
            Image(systemName: attachment.kind == .image ? "photo" : "doc")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.fileName)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(attachment.formattedSize)
                    .foregroundStyle(WIXTheme.textMuted)
                    .font(.caption2)
            }
            Button {
                onRemoveAttachment(attachment)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(WIXTheme.textSecondary)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}
