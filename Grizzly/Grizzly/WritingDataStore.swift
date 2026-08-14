import Foundation
import Observation

/// Shared, in-memory cache of TrackBear data for the current session.
/// Centralizing this avoids every tab re-fetching the same projects/tallies.
@Observable
final class WritingDataStore {
    var projects: [Project] = []
    var tallies: [Tally] = []
    var leaderboards: [Leaderboard] = []
    var isLoadingProjects = false
    var isLoadingTallies = false
    var isLoadingLeaderboards = false
    var lastError: String?

    func refreshProjects(using settings: AppSettingsStore) async {
        if settings.isDemoMode {
            if projects.isEmpty {
                projects = DemoData.projects
            }
            lastError = nil
            return
        }
        guard let client = settings.makeClient() else {
            lastError = TrackBearError.notConfigured.errorDescription
            return
        }
        isLoadingProjects = true
        defer { isLoadingProjects = false }
        do {
            projects = try await client.listProjects()
                .sorted { ($0.lastUpdated ?? "") > ($1.lastUpdated ?? "") }
            lastError = nil
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refreshTallies(using settings: AppSettingsStore) async {
        if settings.isDemoMode {
            if tallies.isEmpty {
                tallies = DemoData.tallies.sorted { $0.date > $1.date }
            }
            lastError = nil
            return
        }
        guard let client = settings.makeClient() else {
            lastError = TrackBearError.notConfigured.errorDescription
            return
        }
        isLoadingTallies = true
        defer { isLoadingTallies = false }
        do {
            tallies = try await client.listTallies()
                .sorted { $0.date > $1.date }
            lastError = nil
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @discardableResult
    func logProgress(_ request: TallyCreateRequest, using settings: AppSettingsStore) async -> Result<Tally, Error> {
        if settings.isDemoMode {
            let created = makeDemoTally(from: request)
            tallies.insert(created, at: 0)
            applyDemoTotals(for: request)
            return .success(created)
        }
        guard let client = settings.makeClient() else {
            return .failure(TrackBearError.notConfigured)
        }
        do {
            let created = try await client.createTally(request)
            tallies.insert(created, at: 0)
            await refreshProjects(using: settings)
            return .success(created)
        } catch {
            return .failure(error)
        }
    }

    func deleteTally(_ tally: Tally, using settings: AppSettingsStore) async {
        if settings.isDemoMode {
            tallies.removeAll { $0.id == tally.id }
            return
        }
        guard let client = settings.makeClient() else { return }
        do {
            try await client.deleteTally(id: tally.id)
            tallies.removeAll { $0.id == tally.id }
            await refreshProjects(using: settings)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refreshLeaderboards(using settings: AppSettingsStore) async {
        if settings.isDemoMode {
            if leaderboards.isEmpty {
                leaderboards = DemoData.leaderboards
            }
            lastError = nil
            return
        }
        guard let client = settings.makeClient() else {
            lastError = TrackBearError.notConfigured.errorDescription
            return
        }
        isLoadingLeaderboards = true
        defer { isLoadingLeaderboards = false }
        do {
            leaderboards = try await client.listLeaderboards()
            lastError = nil
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @discardableResult
    func joinLeaderboard(joinCode: String, displayName: String, using settings: AppSettingsStore) async -> Result<Leaderboard, Error> {
        if settings.isDemoMode {
            // The sample board is already in the list; pretend the join succeeded.
            let board = DemoData.leaderboards.first { $0.uuid == "demo-sprint" } ?? DemoData.leaderboards[0]
            await refreshLeaderboards(using: settings)
            return .success(board)
        }
        guard let client = settings.makeClient() else {
            return .failure(TrackBearError.notConfigured)
        }
        do {
            let board = try await client.getLeaderboard(joinCode: joinCode)
            let request = LeaderboardJoinRequest(
                displayName: displayName,
                color: "",
                isParticipant: true,
                goal: LeaderboardGoal(measure: .word, count: 0)
            )
            _ = try await client.joinLeaderboard(uuid: board.uuid, request)
            await refreshLeaderboards(using: settings)
            return .success(board)
        } catch {
            return .failure(error)
        }
    }

    // MARK: Demo helpers

    /// Builds a `Tally` for a locally-logged demo entry, giving it an id below
    /// any existing one so it never collides with the fixtures.
    private func makeDemoTally(from request: TallyCreateRequest) -> Tally {
        let nextId = (tallies.map(\.id).min() ?? 0) - 1
        let work = request.workId.flatMap { id in projects.first { $0.id == id } }
        return Tally(
            id: nextId, uuid: "demo-tally-\(nextId)", createdAt: nil, updatedAt: nil,
            state: "active", ownerId: 1,
            date: request.date, measure: request.measure, count: request.count,
            note: request.note.isEmpty ? nil : request.note,
            workId: request.workId, work: work, tags: nil
        )
    }

    /// Reflects a logged demo entry in the affected project's running totals so
    /// the Projects tab updates immediately.
    private func applyDemoTotals(for request: TallyCreateRequest) {
        guard let workId = request.workId,
              let index = projects.firstIndex(where: { $0.id == workId }) else { return }
        var totals = projects[index].totals ?? MeasureCounts(word: nil, time: nil, page: nil, chapter: nil, scene: nil, line: nil)
        let current = totals.value(for: request.measure)
        let newValue = (request.setTotal ?? false) ? request.count : current + request.count
        switch request.measure {
        case .word: totals.word = newValue
        case .time: totals.time = newValue
        case .page: totals.page = newValue
        case .chapter: totals.chapter = newValue
        case .scene: totals.scene = newValue
        case .line: totals.line = newValue
        }
        projects[index].totals = totals
    }
}
