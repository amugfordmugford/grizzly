import SwiftUI

struct JoinLeaderboardView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    @State private var joinCode = ""
    @State private var displayName = ""
    @State private var preview: Leaderboard?
    @State private var isLookingUp = false
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Join Code") {
                    TextField("e.g. ABC123", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button {
                        Task { await lookUp() }
                    } label: {
                        if isLookingUp {
                            ProgressView()
                        } else {
                            Text("Find")
                        }
                    }
                    .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLookingUp)
                }

                if let preview {
                    Section("Leaderboard") {
                        Text(preview.title).font(.headline)
                        if let description = preview.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Display Name") {
                        TextField("How you'll appear on this board", text: $displayName)
                    }

                    Section {
                        Button {
                            Task { await join() }
                        } label: {
                            if isJoining {
                                ProgressView()
                            } else {
                                Text("Join")
                            }
                        }
                        .disabled(isJoining)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Join Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func lookUp() async {
        guard let client = settings.makeClient() else {
            errorMessage = TrackBearError.notConfigured.errorDescription
            return
        }
        isLookingUp = true
        errorMessage = nil
        preview = nil
        defer { isLookingUp = false }
        do {
            preview = try await client.getLeaderboard(joinCode: joinCode.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func join() async {
        isJoining = true
        errorMessage = nil
        defer { isJoining = false }

        switch await dataStore.joinLeaderboard(
            joinCode: joinCode.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            using: settings
        ) {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    JoinLeaderboardView()
        .environment(AppSettingsStore())
        .environment(WritingDataStore())
}
