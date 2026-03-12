import SwiftUI

@main
struct WIXApp: App {
    @StateObject private var config = AppConfigStore()

    var body: some Scene {
        WindowGroup {
            RootView(config: config)
                .preferredColorScheme(.dark)
        }
    }
}

private struct RootView: View {
    @ObservedObject var config: AppConfigStore
    @StateObject private var viewModel: ChatViewModel

    init(config: AppConfigStore) {
        self.config = config
        _viewModel = StateObject(wrappedValue: ChatViewModel(config: config))
    }

    var body: some View {
        ZStack {
            WIXBackdrop()
                .ignoresSafeArea()

            ChatView(viewModel: viewModel, config: config)
                .blur(radius: config.hasSeenOnboarding ? 0 : 8)
                .scaleEffect(config.hasSeenOnboarding ? 1 : 0.985)
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: config.hasSeenOnboarding)

            if !config.hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                        config.hasSeenOnboarding = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }
}
