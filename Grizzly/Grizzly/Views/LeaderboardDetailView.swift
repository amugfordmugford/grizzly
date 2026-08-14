import SwiftUI
import Charts

struct LeaderboardDetailView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let board: Leaderboard

    @State private var participants: [LeaderboardParticipant] = []
    @State private var isLoading = false
    @State private var lastError: String?

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                landscapeChart
            } else {
                portraitContent
            }
        }
        .task {
            await load()
        }
        .overlay {
            if isLoading && participants.isEmpty {
                ProgressView()
            }
        }
        .alert("Something Went Wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lastError ?? "")
        }
    }

    /// Rotating to landscape hands the whole screen to the chart, matching
    /// how Health/Stocks expand their charts on rotation.
    private var landscapeChart: some View {
        Group {
            if LeaderboardChartView.hasData(participants) {
                LeaderboardChartView(participants: participants)
                    .padding()
            } else {
                Text("No progress logged yet")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var portraitContent: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(board.title)
                            .font(.title2.bold())
                        if board.starred == true {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    if let description = board.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Details") {
                if let range = dateRange {
                    LabeledContent("Dates", value: range)
                }
                if let measures = board.measures, !measures.isEmpty {
                    LabeledContent("Measures", value: measures.map(\.displayName).joined(separator: ", "))
                }
                if board.individualGoalMode == true {
                    LabeledContent("Goal", value: "Individual")
                } else if let goal = board.goal {
                    ForEach(goalRows(goal), id: \.0) { measure, value in
                        LabeledContent(measure.displayName, value: "\(value) \(measure.unitHint)")
                    }
                }
            }

            Section("Progress") {
                if participants.isEmpty && !isLoading {
                    Text("No participants yet")
                        .foregroundStyle(.secondary)
                } else if LeaderboardChartView.hasData(participants) {
                    LeaderboardChartView(participants: participants)
                        .frame(height: 220)
                        .padding(.vertical, 4)
                }
            }

            Section("Standings") {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    let rank = index + 1
                    HStack(alignment: .top, spacing: 10) {
                        rankBadge(rank)
                        Circle()
                            .fill(LeaderboardChartView.color(for: participant, among: participants))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(participant.displayName)
                                    .font(.headline)
                                Spacer()
                                Text(progressText(for: participant))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let goalCount = participant.goal?.count, goalCount > 0 {
                                ProgressView(value: Double(participant.progressCount), total: Double(goalCount))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await load()
        }
    }

    private var sortedParticipants: [LeaderboardParticipant] {
        participants.sorted { $0.progressCount > $1.progressCount }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { lastError != nil },
            set: { if !$0 { lastError = nil } }
        )
    }

    private var dateRange: String? {
        switch (board.startDate, board.endDate) {
        case let (start?, end?): return "\(start) – \(end)"
        case let (start?, nil): return "From \(start)"
        case let (nil, end?): return "Until \(end)"
        default: return nil
        }
    }

    private func goalRows(_ goal: MeasureCounts) -> [(Measure, Int)] {
        Measure.allCases.compactMap { measure in
            let value = goal.value(for: measure)
            return value > 0 ? (measure, value) : nil
        }
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = switch rank {
        case 1: Color(red: 0.83, green: 0.68, blue: 0.21)
        case 2: Color(red: 0.68, green: 0.68, blue: 0.70)
        case 3: Color(red: 0.72, green: 0.45, blue: 0.20)
        default: .secondary
        }
        if rank <= 50 {
            Image(systemName: "\(rank).circle.fill")
                .foregroundStyle(color)
                .font(.title3)
        } else {
            Text("#\(rank)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(color)
                .frame(width: 22)
        }
    }

    private func progressText(for participant: LeaderboardParticipant) -> String {
        guard let measure = participant.progressMeasure else { return "No entries yet" }
        if let goalCount = participant.goal?.count, goalCount > 0 {
            return "\(participant.progressCount) / \(goalCount) \(measure.unitHint)"
        }
        return "\(participant.progressCount) \(measure.unitHint)"
    }

    private func load() async {
        if settings.isDemoMode {
            participants = DemoData.participants(forBoardUUID: board.uuid)
            return
        }
        guard let client = settings.makeClient() else {
            lastError = TrackBearError.notConfigured.errorDescription
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            participants = try await client.listLeaderboardParticipants(uuid: board.uuid)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardDetailView(board: Leaderboard(
            id: 1, uuid: "preview", title: "NaNoWriMo 2026", description: "Write 50,000 words in a month.",
            startDate: "2026-11-01", endDate: "2026-11-30", individualGoalMode: false,
            measures: [.word], goal: MeasureCounts(word: 50000, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
            isJoinable: true, starred: true,
            members: nil
        ))
        .environment(AppSettingsStore())
    }
}
