import SwiftUI

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settings
    var isOnboarding = false

    @State private var baseURLText = ""
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

            Section("TrackBear API Token") {
                SecureField("API token", text: $tokenText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Link("Get a token from trackbear.app", destination: URL(string: "https://trackbear.app/account/api-keys")!)
            }

            Section("Server") {
                TextField("Base URL", text: $baseURLText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
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

            if !isOnboarding {
                Section {
                    Button("Sign Out", role: .destructive) {
                        settings.clearToken()
                        tokenText = ""
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            baseURLText = settings.baseURLString
            tokenText = settings.apiToken
        }
    }

    private func testAndSave() async {
        isTesting = true
        testResultMessage = nil
        defer { isTesting = false }

        let trimmedToken = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmedURL) else {
            testSucceeded = false
            testResultMessage = "That server URL doesn't look right."
            return
        }

        let client = TrackBearAPIClient(baseURL: url, token: trimmedToken)
        do {
            try await client.pingWithToken()
            settings.baseURLString = trimmedURL
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
