import SwiftUI

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settings
    var isOnboarding = false

    @State private var tokenText = ""
    @State private var isTesting = false
    @State private var testResultMessage: String?
    @State private var testSucceeded = false

    var body: some View {
        Form {
            if isOnboarding {
                Section {
                    Text("Connect Grizzly to your TrackBear account to start logging writing progress.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if settings.isDemoMode {
                Section {
                    Label("You're exploring the demo", systemImage: "wand.and.stars")
                        .font(.headline)
                    Text("Grizzly is showing sample data so you can try every feature. Exit the demo and add your API token below to connect your own TrackBear account.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Exit Demo Mode", role: .destructive) {
                        settings.isDemoMode = false
                        tokenText = settings.apiToken
                    }
                }
            }

            Section("TrackBear API Token") {
                SecureField("API token", text: $tokenText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                VStack(alignment: .leading, spacing: 6) {
                    Text("To get your API key:")
                        .fontWeight(.semibold)
                    Text("1. [Log in to your TrackBear account.](https://trackbear.app)")
                    Text("2. Tap your name in the top right corner and select **API Keys** from the menu.")
                    Text("3. Tap **New**.")
                    Text("4. Give your key a name, and choose how long it should stay valid. If it expires, you'll need to create a new one to keep this app connected.")
                    Text("5. Tap **Create**.")
                    Text("6. Copy the API key it shows you — it probably starts with \"tb.\"")
                    Text("7. Paste that key into the field above.")
                    Text("8. Tap the **\(isOnboarding ? "Connect" : "Test Connection & Save")** button below. You should see a green checkmark that says \"Connected.\"")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    Task { await testAndSave() }
                } label: {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text(isOnboarding ? "Connect" : "Test Connection & Save")
                    }
                }
                .disabled(tokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                if let testResultMessage {
                    Label(testResultMessage, systemImage: testSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(testSucceeded ? .green : .red)
                        .font(.footnote)
                }
            }

            if isOnboarding {
                Section {
                    Button {
                        settings.startDemo()
                    } label: {
                        Label("Try the Demo", systemImage: "wand.and.stars")
                    }
                } footer: {
                    Text("No account? Explore Grizzly with sample data first — no token required.")
                }
            }

            if !isOnboarding {
                Section {
                    Button("Sign Out", role: .destructive) {
                        settings.clearToken()
                        tokenText = ""
                    }
                }
            }

            Section {
                VStack(spacing: 4) {
                    Text("Made with love by Andrew.")
                    Link("Contact me at jointcommand@icloud.com", destination: URL(string: "mailto:jointcommand@icloud.com")!)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Settings")
        .onAppear {
            tokenText = settings.apiToken
        }
    }

    private func testAndSave() async {
        isTesting = true
        testResultMessage = nil
        defer { isTesting = false }

        let trimmedToken = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = settings.baseURL else {
            testSucceeded = false
            testResultMessage = "That server URL doesn't look right."
            return
        }

        let client = TrackBearAPIClient(baseURL: url, token: trimmedToken)
        do {
            try await client.pingWithToken()
            settings.apiToken = trimmedToken
            testSucceeded = true
            testResultMessage = "Connected."
        } catch {
            testSucceeded = false
            testResultMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppSettingsStore())
    }
}
