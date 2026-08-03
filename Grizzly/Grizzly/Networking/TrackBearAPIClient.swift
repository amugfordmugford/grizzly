import Foundation

enum TrackBearError: LocalizedError {
    case notConfigured
    case invalidURL
    case server(status: Int, message: String)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your TrackBear API token in Settings first."
        case .invalidURL:
            return "That server URL doesn't look right."
        case .server(let status, let message):
            return "TrackBear returned an error (\(status)): \(message)"
        case .decoding:
            return "Couldn't understand TrackBear's response."
        case .transport(let error):
            return error.localizedDescription
        }
    }
}

/// Talks to the TrackBear REST API (https://help.trackbear.app/api/).
/// Every request needs `Authorization: Bearer <token>` plus a descriptive
/// User-Agent, per TrackBear's authentication docs.
struct TrackBearAPIClient {
    var baseURL: URL
    var token: String

    private let userAgent = "Grizzly/1.0 (+https://github.com/amugfordmugford/grizzly)"
    private let session = URLSession.shared

    private var decoder: JSONDecoder {
        JSONDecoder()
    }

    private var encoder: JSONEncoder {
        JSONEncoder()
    }

    private func request(path: String, method: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw TrackBearError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw TrackBearError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TrackBearError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TrackBearError.transport(URLError(.badServerResponse))
        }

        guard (200...299).contains(http.statusCode) else {
            let message = (try? decoder.decode(TrackBearErrorBody.self, from: data))?.error?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw TrackBearError.server(status: http.statusCode, message: message)
        }

        if data.isEmpty, let empty = EmptyResponse() as? T {
            return empty
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TrackBearError.decoding(error)
        }
    }

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let req = try request(path: path, method: "GET", queryItems: queryItems)
        return try await send(req)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        var req = try request(path: path, method: "POST")
        req.httpBody = try encoder.encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await send(req)
    }

    func delete(_ path: String) async throws {
        let req = try request(path: path, method: "DELETE")
        let _: EmptyResponse = try await send(req)
    }

    // MARK: Endpoints

    func listProjects() async throws -> [Project] {
        try await get("project")
    }

    func listTallies(workId: Int? = nil) async throws -> [Tally] {
        var items: [URLQueryItem] = []
        if let workId {
            items.append(URLQueryItem(name: "works", value: String(workId)))
        }
        return try await get("tally", queryItems: items)
    }

    func createTally(_ body: TallyCreateRequest) async throws -> Tally {
        try await post("tally", body: body)
    }

    func deleteTally(id: Int) async throws {
        try await delete("tally/\(id)")
    }

    /// Validates the token by hitting the authenticated ping endpoint.
    func pingWithToken() async throws {
        let _: EmptyResponse = try await get("ping/api-token")
    }
}

/// Some endpoints (ping, delete) return a body too minimal to be worth modeling precisely.
/// The empty `init` accepts whatever shape the server sends back.
struct EmptyResponse: Decodable {
    init(from decoder: Decoder) throws {}
}
