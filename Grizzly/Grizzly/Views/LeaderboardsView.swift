import SwiftUI

struct LeaderboardsView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    @State private var showJoinSheet = false

    var body: some View {
        List {
            if dataStore.leaderboards.isEmpty && !dataStore.isLoadingLeaderboards {
                ContentUnavailableView(
                    "No Leaderboards Yet",
                    systemImage: "trophy",
                    description: Text("Join one with a code, or create one in TrackBear.")
                )
            }
            ForEach(dataStore.leaderboards) { board in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(board.title)
                            .font(.headline)
                        if board.starred == true {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    if let range = dateRange(board) {
                        Text(range)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let count = board.members?.count, count > 0 {
                        Text("\(count) participant\(count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("Leaderboards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showJoinSheet = true
                } label: {
                    Label("Join", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinLeaderboardView()
        }
        .refreshable {
            await dataStore.refreshLeaderboards(using: settings)
        }
        .task {
            if dataStore.leaderboards.isEmpty {
                await dataStore.refreshLeaderboards(using: settings)
            }
        }
        .overlay {
            if dataStore.isLoadingLeaderboards && dataStore.leaderboards.isEmpty {
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

    private func dateRange(_ board: Leaderboard) -> String? {
        switch (board.startDate, board.endDate) {
        case let (start?, end?): return "\(start) – \(end)"
        case let (start?, nil): return "From \(start)"
        case let (nil, end?): return "Until \(end)"
        default: return nil
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardsView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
