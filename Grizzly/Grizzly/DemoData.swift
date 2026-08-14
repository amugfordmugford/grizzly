import Foundation

/// Canned sample data used by Demo Mode so the app's full feature set can be
/// explored (and reviewed) without a TrackBear account or API token. Nothing
/// here touches the network; Demo Mode short-circuits every call in
/// `WritingDataStore` and the detail views to these fixtures.
enum DemoData {

    // MARK: Dates

    /// A `YYYY-MM-DD` string for `offset` days from today (negative = past),
    /// so History buckets (Today / Yesterday / This Week / Earlier) and the
    /// leaderboard charts always look current no matter when the app is opened.
    private static func day(_ offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        return DateFormatter.trackBearDate.string(from: date)
    }

    // MARK: Projects

    static var projects: [Project] {
        [
            Project(
                id: 101, uuid: "demo-salt-road", createdAt: nil, updatedAt: nil,
                state: "active", ownerId: 1,
                title: "The Salt Road",
                description: "A caravan epic across a drowned desert.",
                phase: "Drafting",
                startingBalance: MeasureCounts(word: 0, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                cover: nil, starred: true, displayOnProfile: true,
                totals: MeasureCounts(word: 42350, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                lastUpdated: day(0)
            ),
            Project(
                id: 102, uuid: "demo-tidewrack", createdAt: nil, updatedAt: nil,
                state: "active", ownerId: 1,
                title: "Tidewrack",
                description: "A coastal murder mystery.",
                phase: "Revising",
                startingBalance: MeasureCounts(word: 0, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                cover: nil, starred: false, displayOnProfile: true,
                totals: MeasureCounts(word: 88200, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                lastUpdated: day(-2)
            ),
            Project(
                id: 103, uuid: "demo-shorts", createdAt: nil, updatedAt: nil,
                state: "active", ownerId: 1,
                title: "Short Stories 2026",
                description: "A collection-in-progress.",
                phase: "Outlining",
                startingBalance: MeasureCounts(word: 0, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                cover: nil, starred: false, displayOnProfile: false,
                totals: MeasureCounts(word: 6400, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                lastUpdated: day(-10)
            ),
        ]
    }

    private static func project(_ id: Int) -> Project? {
        projects.first { $0.id == id }
    }

    // MARK: Tallies

    static var tallies: [Tally] {
        func tally(_ id: Int, _ dayOffset: Int, _ count: Int, workId: Int, _ note: String?) -> Tally {
            Tally(
                id: id, uuid: "demo-tally-\(id)", createdAt: nil, updatedAt: nil,
                state: "active", ownerId: 1,
                date: day(dayOffset), measure: .word, count: count, note: note,
                workId: workId, work: project(workId), tags: nil
            )
        }
        return [
            tally(9001, 0, 1200, workId: 101, "Morning pages before work."),
            tally(9002, 0, 300, workId: 103, nil),
            tally(9003, -1, 850, workId: 101, "Finally cracked the market scene."),
            tally(9004, -2, 1500, workId: 102, "Tightened the pacing in chapter 12."),
            tally(9005, -4, 640, workId: 101, nil),
            tally(9006, -6, 2000, workId: 102, "Big revision push over the weekend."),
            tally(9007, -10, 430, workId: 103, "Outlined two new stories."),
            tally(9008, -15, 1750, workId: 101, nil),
        ]
    }

    static func tallies(forWorkId workId: Int) -> [Tally] {
        tallies.filter { $0.workId == workId }
    }

    // MARK: Leaderboards

    static var leaderboards: [Leaderboard] {
        [
            Leaderboard(
                id: 201, uuid: "demo-nano", title: "NaNoWriMo 2026",
                description: "Write 50,000 words in a month with friends.",
                startDate: day(-12), endDate: day(18),
                individualGoalMode: false,
                measures: [.word],
                goal: MeasureCounts(word: 50000, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
                isJoinable: true, starred: true,
                members: DemoData.nanoParticipants.map {
                    LeaderboardMember(id: $0.id, displayName: $0.displayName, avatar: nil,
                                      isParticipant: true, isOwner: $0.id == 301, userUuid: $0.uuid)
                }
            ),
            Leaderboard(
                id: 202, uuid: "demo-sprint", title: "Summer Word Sprint",
                description: "A friendly two-week sprint. Set your own goal.",
                startDate: day(-5), endDate: day(9),
                individualGoalMode: true,
                measures: [.word],
                goal: nil,
                isJoinable: true, starred: false,
                members: DemoData.sprintParticipants.map {
                    LeaderboardMember(id: $0.id, displayName: $0.displayName, avatar: nil,
                                      isParticipant: true, isOwner: $0.id == 311, userUuid: $0.uuid)
                }
            ),
        ]
    }

    static func participants(forBoardUUID uuid: String) -> [LeaderboardParticipant] {
        switch uuid {
        case "demo-nano": return nanoParticipants
        case "demo-sprint": return sprintParticipants
        default: return []
        }
    }

    private static func wordTallies(_ perDay: [(Int, Int)]) -> [LeaderboardParticipantTally] {
        perDay.map { offset, count in
            LeaderboardParticipantTally(uuid: nil, date: day(offset), measure: .word, count: count)
        }
    }

    private static var nanoParticipants: [LeaderboardParticipant] {
        [
            LeaderboardParticipant(
                id: 301, uuid: "demo-you", displayName: "You", avatar: nil, color: "#4E79A7",
                goal: LeaderboardGoal(measure: .word, count: 50000),
                tallies: wordTallies([(-12, 1600), (-9, 2100), (-6, 1800), (-4, 1900), (-2, 2200), (0, 1200)])
            ),
            LeaderboardParticipant(
                id: 302, uuid: "demo-river", displayName: "River", avatar: nil, color: "#F28E2B",
                goal: LeaderboardGoal(measure: .word, count: 50000),
                tallies: wordTallies([(-12, 2000), (-10, 2500), (-7, 2300), (-5, 2100), (-3, 2600), (-1, 2400)])
            ),
            LeaderboardParticipant(
                id: 303, uuid: "demo-sam", displayName: "Sam", avatar: nil, color: "#59A14F",
                goal: LeaderboardGoal(measure: .word, count: 50000),
                tallies: wordTallies([(-11, 900), (-8, 1200), (-6, 800), (-3, 1500), (-1, 1100)])
            ),
            LeaderboardParticipant(
                id: 304, uuid: "demo-marisol", displayName: "Marisol", avatar: nil, color: "#E15759",
                goal: LeaderboardGoal(measure: .word, count: 50000),
                tallies: wordTallies([(-12, 1400), (-9, 1600), (-6, 1700), (-4, 1500), (-2, 1800), (0, 900)])
            ),
        ]
    }

    private static var sprintParticipants: [LeaderboardParticipant] {
        [
            LeaderboardParticipant(
                id: 311, uuid: "demo-you", displayName: "You", avatar: nil, color: "#4E79A7",
                goal: LeaderboardGoal(measure: .word, count: 15000),
                tallies: wordTallies([(-5, 1200), (-3, 1500), (-1, 1300), (0, 900)])
            ),
            LeaderboardParticipant(
                id: 312, uuid: "demo-priya", displayName: "Priya", avatar: nil, color: "#B07AA1",
                goal: LeaderboardGoal(measure: .word, count: 10000),
                tallies: wordTallies([(-5, 1000), (-4, 1100), (-2, 1400), (0, 1200)])
            ),
            LeaderboardParticipant(
                id: 313, uuid: "demo-theo", displayName: "Theo", avatar: nil, color: "#76B7B2",
                goal: LeaderboardGoal(measure: .word, count: 20000),
                tallies: wordTallies([(-5, 1800), (-3, 2000), (-1, 1700)])
            ),
        ]
    }
}
