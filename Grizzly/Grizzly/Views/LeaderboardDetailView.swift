import SwiftUI

struct LeaderboardDetailView: View {
    let board: Leaderboard

    var body: some View {
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

            Section("Participants") {
                let participants = board.members?.filter { $0.isParticipant != false } ?? []
                if participants.isEmpty {
                    Text("No participants yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(participants) { member in
                        HStack {
                            Text(member.displayName)
                            if member.isOwner == true {
                                Spacer()
                                Text("Owner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationStack {
        LeaderboardDetailView(board: Leaderboard(
            id: 1, uuid: "preview", title: "NaNoWriMo 2026", description: "Write 50,000 words in a month.",
            startDate: "2026-11-01", endDate: "2026-11-30", individualGoalMode: false,
            measures: [.word], goal: MeasureCounts(word: 50000, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
            isJoinable: true, starred: true,
            members: [
                LeaderboardMember(id: 1, displayName: "You", avatar: nil, isParticipant: true, isOwner: true, userUuid: nil),
                LeaderboardMember(id: 2, displayName: "A Friend", avatar: nil, isParticipant: true, isOwner: false, userUuid: nil)
            ]
        ))
    }
}
