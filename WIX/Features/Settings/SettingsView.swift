import SwiftUI

struct SettingsView: View {
    @ObservedObject var config: AppConfigStore
    let onClearAll: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                WIXBackdrop()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        settingsCard(
                            title: "Gemini API -avain",
                            subtitle: "Syötä oma avain. Se tallennetaan Keychainiin tällä laitteella."
                        ) {
                            SecureField("AIza...", text: $config.apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(16)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        settingsCard(
                            title: "Mallin nimi",
                            subtitle: "Voit käyttää esimerkiksi flash-, flash-lite- tai latest-mallia."
                        ) {
                            TextField("gemini-flash-lite-latest", text: $config.modelName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(16)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        settingsCard(
                            title: "Oletustila",
                            subtitle: "Vaihda nopeasti nopean ja analyyttisen moodin välillä."
                        ) {
                            VStack(spacing: 10) {
                                ForEach(ResponseMode.allCases) { mode in
                                    Button {
                                        config.selectedMode = mode
                                    } label: {
                                        HStack {
                                            Label(mode.title, systemImage: mode.symbolName)
                                            Spacer()
                                            if config.selectedMode == mode {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                        }
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(16)
                                        .background(
                                            config.selectedMode == mode ? Color.white.opacity(0.10) : Color.white.opacity(0.05),
                                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        settingsCard(
                            title: "Paikallinen muisti",
                            subtitle: "Keskustelut palautuvat laitteelta seuraavalla avauskerralla."
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Chat-historia tallennetaan Application Support -hakemistoon.", systemImage: "internaldrive")
                                Label("Liitteet tallennetaan paikallisesti laitteelle.", systemImage: "folder")
                                Label("API-avain tallennetaan Keychainiin.", systemImage: "lock.shield")
                            }
                            .font(.subheadline)
                            .foregroundStyle(WIXTheme.textSecondary)
                        }

                        settingsCard(
                            title: "Data",
                            subtitle: "Poista kaikki paikallisesti tallennettu sisältö tästä laitteesta."
                        ) {
                            Button(role: .destructive) {
                                onClearAll()
                                dismiss()
                            } label: {
                                Label("Tyhjennä paikallinen muisti", systemImage: "trash")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Asetukset")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Valmis") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(WIXTheme.textSecondary)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
