
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var config: AppConfigStore

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showMenu = false

    var body: some View {
        ZStack {
            WIXBackdrop()
                .ignoresSafeArea()

            mainContent

            if showMenu {
                SidebarMenuView(isOpen: $showMenu)
                    .transition(.move(edge: .leading))
                    .zIndex(5)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showMenu)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            conversationBody
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                showMenu.toggle()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading) {
                Text("WIX! \(config.selectedMode.title)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(config.modelName)
                    .font(.caption)
                    .foregroundStyle(WIXTheme.textSecondary)
            }

            Spacer()

            Button {
                viewModel.isShowingSettings = true
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var conversationBody: some View {
        ScrollView {
            VStack(spacing: 18) {
                ForEach(viewModel.messages) { message in
                    MessageBubbleView(message: message)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
        .safeAreaInset(edge: .bottom) {
            ComposerBar(
                text: $viewModel.composerText,
                mode: $config.selectedMode,
                attachments: viewModel.draftAttachments,
                isStreaming: viewModel.isStreaming,
                canSend: viewModel.canSend,
                onPlusTapped: {},
                onMicTapped: {},
                onRemoveAttachment: viewModel.removeDraftAttachment,
                onSend: viewModel.sendMessage,
                onStop: { viewModel.stopStreaming(markAsCancelled: true) }
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
}
