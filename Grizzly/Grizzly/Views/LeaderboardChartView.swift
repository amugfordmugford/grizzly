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
        .chartLegend(position: .bottom, spacing: 8)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: Self.visibleDomainSeconds)
    }

    /// A two-week window by default — long enough to see a trend, short enough
    /// that a month-plus board (NaNoWriMo, etc.) is worth scrolling through
    /// rather than squeezed flat. Boards shorter than this just show everything.
    private static let visibleDomainSeconds: TimeInterval = 60 * 60 * 24 * 14

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
