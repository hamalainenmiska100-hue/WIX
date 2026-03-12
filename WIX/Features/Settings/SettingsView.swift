import SwiftUI

struct SettingsView: View {

    @ObservedObject var config: AppConfigStore

    var body: some View {

        NavigationStack {

            Form {

                Section("Gemini") {

                    TextField(
                        "API Key",
                        text: $config.apiKey
                    )

                    TextField(
                        "Model",
                        text: $config.modelName
                    )

                }

                Section("Tietoa") {

                    Text("WIX AI Chat")
                    Text("Monokromaattinen Gemini chat")

                }

            }
            .navigationTitle("Asetukset")

        }
    }
}
