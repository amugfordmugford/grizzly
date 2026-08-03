import Foundation
import Observation

/// Shared, in-memory cache of TrackBear data for the current session.
/// Centralizing this avoids every tab re-fetching the same projects/tallies.
@Observable
final class WritingDataStore {
    var projects: [Project] = []
    var tallies: [Tally] = []
    var isLoadingProjects = false
    var isLoadingTallies = false
    var lastError: String?

    func refreshProjects(using settings: AppSettingsStore) async {
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
        guard let client = settings.makeClient() else { return }
        do {
            try await client.deleteTally(id: tally.id)
            tallies.removeAll { $0.id == tally.id }
            await refreshProjects(using: settings)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
