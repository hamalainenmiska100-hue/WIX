import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @State private var pulse = false

    private let pages: [Page] = [
        .init(
            title: "Tervetuloa WIX!:iin",
            subtitle: "Monokromaattinen AI-chat iOS:lle.",
            footnote: "Ulkoasu on kevyt, tumma ja tarkoituksella yksinkertainen."
        ),
        .init(
            title: "Oma API-avain, oma malli",
            subtitle: "Syötä Gemini API -avain ja mallin nimi itse.",
            footnote: "API-avain tallennetaan Keychainiin ja keskustelut jäävät laitteelle."
        ),
        .init(
            title: "Kuvat, tiedostot ja streaming",
            subtitle: "Lähetä sisältöä ja katso vastauksen muodostuvan reaaliajassa.",
            footnote: "Mukana paikallinen muisti, liitteet ja pehmeät siirtymät."
        )
    ]

    var body: some View {
        ZStack {
            WIXBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 30)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(pulse ? 0.10 : 0.05))
                        .frame(width: 230, height: 230)
                        .blur(radius: pulse ? 32 : 18)
                        .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: pulse)

                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 190, height: 190)
                        .overlay(
                            RoundedRectangle(cornerRadius: 42, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .overlay(
                            Text("WIX!")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .rotationEffect(.degrees(pulse ? 2 : -2))
                        .animation(.spring(response: 1.2, dampingFraction: 0.72).repeatForever(autoreverses: true), value: pulse)
                }
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 16) {
                            Text(item.title)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(item.subtitle)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Text(item.footnote)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.58))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 250)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Color.white : Color.white.opacity(0.22))
                            .frame(width: index == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: page)
                    }
                }

                Spacer()

                Button(action: advance) {
                    HStack(spacing: 10) {
                        Text(page == pages.count - 1 ? "Aloita" : "Jatka")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            pulse = true
        }
    }

    private func advance() {
        Haptics.tap()
        if page < pages.count - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                page += 1
            }
        } else {
            onFinish()
        }
    }
}

private extension OnboardingView {
    struct Page {
        let title: String
        let subtitle: String
        let footnote: String
    }
}
