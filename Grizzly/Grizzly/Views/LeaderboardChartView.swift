import SwiftUI
import Charts

/// Cumulative progress-over-time chart, one line per participant.
/// Shared between the embedded (portrait) and full-screen (landscape) layouts.
struct LeaderboardChartView: View {
    let participants: [LeaderboardParticipant]

    var body: some View {
        Chart {
            ForEach(participants) { participant in
                ForEach(Self.cumulativeSeries(for: participant), id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(by: .value("Participant", participant.displayName))
                }
            }
        }
        .chartForegroundStyleScale(
            domain: participants.map(\.displayName),
            range: participants.map { color(for: $0) }
        )
        .chartLegend(position: .bottom, spacing: 8)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: Self.visibleDomainSeconds)
    }

    /// A two-week window by default — long enough to see a trend, short enough
    /// that a month-plus board (NaNoWriMo, etc.) is worth scrolling through
    /// rather than squeezed flat. Boards shorter than this just show everything.
    private static let visibleDomainSeconds: TimeInterval = 60 * 60 * 24 * 14

    /// Assigns each participant a stable color by their position in the
    /// original (unsorted) list, so the same person is always the same color
    /// here and in the Standings list below, regardless of how either is sorted.
    static let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .yellow, .indigo, .mint, .cyan]

    func color(for participant: LeaderboardParticipant) -> Color {
        Self.color(for: participant, among: participants)
    }

    static func color(for participant: LeaderboardParticipant, among participants: [LeaderboardParticipant]) -> Color {
        guard let index = participants.firstIndex(where: { $0.id == participant.id }) else { return .secondary }
        return palette[index % palette.count]
    }

    static func hasData(_ participants: [LeaderboardParticipant]) -> Bool {
        participants.contains { !cumulativeSeries(for: $0).isEmpty }
    }

    static func cumulativeSeries(for participant: LeaderboardParticipant) -> [(date: Date, total: Int)] {
        guard let measure = participant.progressMeasure else { return [] }
        let points = (participant.tallies ?? [])
            .filter { $0.measure == measure }
            .compactMap { tally -> (Date, Int)? in
                guard let date = DateFormatter.trackBearDate.date(from: tally.date) else { return nil }
                return (date, tally.count)
            }
            .sorted { $0.0 < $1.0 }

        var running = 0
        return points.map { date, count in
            running += count
            return (date, running)
        }
    }
}
