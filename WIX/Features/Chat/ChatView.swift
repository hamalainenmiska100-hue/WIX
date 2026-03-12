import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var config: AppConfigStore

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isShowingPhotoPicker = false
    @State private var isShowingAttachmentOptions = false

    var body: some View {
        ZStack {
            WIXBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                conversationBody
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(config: config) {
                viewModel.clearEverything()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.black)
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFileImporter,
            allowedContentTypes: [.item, .pdf, .plainText, .json, .commaSeparatedText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.addFiles(from: urls)
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        PhotosPicker(
    selection: $selectedPhotoItems,
    maxSelectionCount: 6,
    matching: .images
) {
    EmptyView()
}
            .labelsHidden()
            .frame(width: 0, height: 0)
            .opacity(0.001)
        }
        .confirmationDialog("Lisää sisältöä", isPresented: $isShowingAttachmentOptions, titleVisibility: .visible) {
            PhotosPicker(
    selection: $selectedPhotoItems,
    maxSelectionCount: 6,
    matching: .images
) {
    Text("Kuvat")
}
            Button("Tiedostot") {
                viewModel.isShowingFileImporter = true
            }
            Button("Asetukset") {
                viewModel.isShowingSettings = true
            }
            if !viewModel.messages.isEmpty {
                Button("Tyhjennä chat", role: .destructive) {
                    viewModel.clearEverything()
                }
            }
            Button("Peruuta", role: .cancel) { }
        }
        .onChange(of: selectedPhotoItems) { newItems in
    guard !newItems.isEmpty else { return }

    Task {
        await viewModel.addPhotos(from: newItems)
        selectedPhotoItems.removeAll()
    }
}
        .alert("Virhe", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.dismissError()
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Tuntematon virhe")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: { isShowingAttachmentOptions = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("WIX!")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(config.selectedMode.title)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WIXTheme.textSecondary)
                }

                Text(config.modelName)
                    .font(.caption)
                    .foregroundStyle(WIXTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.isShowingSettings = true
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var conversationBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    if viewModel.messages.isEmpty {
                        emptyState
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 160)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.last?.id) { _, lastID in
                guard let lastID else { return }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            ComposerBar(
                text: $viewModel.composerText,
                mode: $config.selectedMode,
                attachments: viewModel.draftAttachments,
                isStreaming: viewModel.isStreaming,
                canSend: viewModel.canSend,
                onPlusTapped: { isShowingAttachmentOptions = true },
                onMicTapped: {
                    viewModel.errorMessage = "Puheohjaus ei ole vielä käytössä tässä paketissa."
                },
                onRemoveAttachment: viewModel.removeDraftAttachment,
                onSend: viewModel.sendMessage,
                onStop: { viewModel.stopStreaming(markAsCancelled: true) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 260)

            HStack(spacing: 14) {
                SuggestionCard(
                    title: "Luo kuva",
                    subtitle: "esitystäni varten"
                ) {
                    config.selectedMode = .instant
                    viewModel.composerText = "Create an image concept for my presentation."
                }

                SuggestionCard(
                    title: "Testaa, mitä tiedän",
                    subtitle: "muinaisista sivilisaatioista"
                ) {
                    config.selectedMode = .analyze
                    viewModel.composerText = "Quiz me on ancient civilizations and explain the answers."
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Simple. Hieno. Monokromaattinen.")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lisää oma Gemini API -avain, lähetä kuvia tai tiedostoja ja anna WIX!:n streamata vastaus reaaliajassa.")
                    .font(.subheadline)
                    .foregroundStyle(WIXTheme.textSecondary)
            }

            if !config.hasValidConfiguration {
                Button {
                    viewModel.isShowingSettings = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "key.horizontal")
                        Text("Avaa asetukset ja lisää API-avain")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
