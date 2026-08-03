import SwiftUI

struct HistoryView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    var body: some View {
        List {
            if dataStore.tallies.isEmpty && !dataStore.isLoadingTallies {
                ContentUnavailableView(
                    "No Progress Logged Yet",
                    systemImage: "clock",
                    description: Text("Entries you log will show up here.")
                )
            }
            ForEach(dataStore.tallies) { tally in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(tally.count) \(tally.measure.unitHint)")
                            .font(.headline)
                        Spacer()
                        Text(tally.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let title = tally.work?.title {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let note = tally.note, !note.isEmpty {
                        Text(note)
                            .font(.footnote)
                    }
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                Task {
                    for index in offsets {
                        await dataStore.deleteTally(dataStore.tallies[index], using: settings)
                    }
                }
            }
        }
        .navigationTitle("History")
        .refreshable {
            await dataStore.refreshTallies(using: settings)
        }
        .task {
            if dataStore.tallies.isEmpty {
                await dataStore.refreshTallies(using: settings)
            }
        }
        .overlay {
            if dataStore.isLoadingTallies && dataStore.tallies.isEmpty {
                ProgressView()
            }
        }
        .alert("Something Went Wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dataStore.lastError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { dataStore.lastError != nil },
            set: { if !$0 { dataStore.lastError = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
