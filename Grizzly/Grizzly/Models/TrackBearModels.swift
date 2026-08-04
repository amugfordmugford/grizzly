import Foundation

/// The units TrackBear measures writing progress in.
enum Measure: String, Codable, CaseIterable, Identifiable {
    case word
    case time
    case page
    case chapter
    case scene
    case line

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .word: return "Words"
        case .time: return "Time"
        case .page: return "Pages"
        case .chapter: return "Chapters"
        case .scene: return "Scenes"
        case .line: return "Lines"
        }
    }

    var unitHint: String {
        switch self {
        case .word: return "words"
        case .time: return "minutes"
        case .page: return "pages"
        case .chapter: return "chapters"
        case .scene: return "scenes"
        case .line: return "lines"
        }
    }
}

/// A per-measure tally, used for both `startingBalance` and `totals` on a project.
struct MeasureCounts: Codable, Equatable {
    var word: Int?
    var time: Int?
    var page: Int?
    var chapter: Int?
    var scene: Int?
    var line: Int?

    func value(for measure: Measure) -> Int {
        switch measure {
        case .word: return word ?? 0
        case .time: return time ?? 0
        case .page: return page ?? 0
        case .chapter: return chapter ?? 0
        case .scene: return scene ?? 0
        case .line: return line ?? 0
        }
    }
}

/// TrackBear calls projects "works" internally; the API path is `/project`.
struct Project: Codable, Identifiable, Equatable {
    let id: Int
    let uuid: String?
    let createdAt: String?
    let updatedAt: String?
    let state: String?
    let ownerId: Int?
    var title: String
    var description: String?
    var phase: String?
    var startingBalance: MeasureCounts?
    var cover: String?
    var starred: Bool?
    var displayOnProfile: Bool?
    var totals: MeasureCounts?
    var lastUpdated: String?

    static func == (lhs: Project, rhs: Project) -> Bool { lhs.id == rhs.id }
}

struct Tag: Codable, Identifiable, Equatable {
    let id: Int
    let uuid: String?
    let name: String
    let color: String?
}

struct Tally: Codable, Identifiable, Equatable {
    let id: Int
    let uuid: String?
    let createdAt: String?
    let updatedAt: String?
    let state: String?
    let ownerId: Int?
    var date: String
    var measure: Measure
    var count: Int
    var note: String?
    var workId: Int?
    var work: Project?
    var tags: [Tag]?

    static func == (lhs: Tally, rhs: Tally) -> Bool { lhs.id == rhs.id }
}

struct TallyCreateRequest: Encodable {
    var date: String
    var measure: Measure
    var count: Int
    /// TrackBear's API requires these keys even when there's nothing to send —
    /// omitting them (as Swift does for a nil Optional) fails server-side validation.
    var note: String
    var workId: Int?
    var setTotal: Bool?
    var tags: [String] = []
}

struct LeaderboardGoal: Codable, Equatable {
    var measure: Measure
    var count: Int
}

struct LeaderboardMember: Codable, Identifiable, Equatable {
    let id: Int
    var displayName: String
    var avatar: String?
    var isParticipant: Bool?
    var isOwner: Bool?
    var userUuid: String?
}

struct Leaderboard: Codable, Identifiable, Equatable {
    let id: Int
    let uuid: String
    var title: String
    var description: String?
    var startDate: String?
    var endDate: String?
    var individualGoalMode: Bool?
    var measures: [Measure]?
    var goal: MeasureCounts?
    var isJoinable: Bool?
    var starred: Bool?
    var members: [LeaderboardMember]?

    static func == (lhs: Leaderboard, rhs: Leaderboard) -> Bool { lhs.id == rhs.id }
}

struct LeaderboardJoinRequest: Encodable {
    var displayName: String
    var color: String
    var isParticipant: Bool
    var goal: LeaderboardGoal
    var workIds: [Int] = []
    var tagIds: [Int] = []
}

/// TrackBear's documented error envelope, used only when a request fails.
struct TrackBearErrorBody: Decodable {
    struct Detail: Decodable {
        let code: String
        let message: String
    }
    let success: Bool?
    let error: Detail?
}

extension DateFormatter {
    /// TrackBear dates are plain `YYYY-MM-DD`, with no time component.
    static let trackBearDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
