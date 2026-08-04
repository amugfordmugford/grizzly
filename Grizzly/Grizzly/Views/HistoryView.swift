import SwiftUI

struct HistoryView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    var body: some View {
        List {
            if dataStore.tallies.isEmpty && !dataStore.isLoadingTallies {
                ContentUnavailableView(
                    "No Progress Logged Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Entries you log will show up here.")
                )
            }
            ForEach(groupedTallies, id: \.title) { group in
                Section(group.title) {
                    ForEach(group.tallies) { tally in
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
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await dataStore.deleteTally(tally, using: settings) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
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

    /// Buckets tallies (already sorted newest-first) into Today / Yesterday /
    /// This Week / Earlier, preserving that order within each bucket.
    private var groupedTallies: [(title: String, tallies: [Tally])] {
        let calendar = Calendar.current
        var buckets: [(title: String, tallies: [Tally])] = []

        func bucketTitle(for date: Date?) -> String {
            guard let date else { return "Earlier" }
            if calendar.isDateInToday(date) { return "Today" }
            if calendar.isDateInYesterday(date) { return "Yesterday" }
            if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
                return "This Week"
            }
            return "Earlier"
        }

        for tally in dataStore.tallies {
            let date = DateFormatter.trackBearDate.date(from: tally.date)
            let title = bucketTitle(for: date)
            if let lastIndex = buckets.indices.last, buckets[lastIndex].title == title {
                buckets[lastIndex].tallies.append(tally)
            } else {
                buckets.append((title, [tally]))
            }
        }
        return buckets
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
