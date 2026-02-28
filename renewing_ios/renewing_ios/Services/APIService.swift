import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = Config.apiBaseURL

    private func authorizedRequest(url: URL, method: String = "GET", body: Data? = nil) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await AuthService.shared.getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body { request.httpBody = body }
        return request
    }

    // MARK: - Listings

    func fetchNearbyListings(
        lat: Double,
        lng: Double,
        radius: Int = Config.defaultSearchRadiusMeters,
        search: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [Listing] {
        var components = URLComponents(string: "\(baseURL)/listings/nearby")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lng", value: "\(lng)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        if let search, !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }

        let request = try await authorizedRequest(url: components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoded = try JSONDecoder().decode(ListingsResponse.self, from: data)
        return decoded.listings
    }

    func fetchListing(id: String) async throws -> Listing {
        let url = URL(string: "\(baseURL)/listings/\(id)")!
        let request = try await authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(Listing.self, from: data)
    }

    func fetchMyListings() async throws -> [Listing] {
        let url = URL(string: "\(baseURL)/listings/my")!
        let request = try await authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoded = try JSONDecoder().decode(ListingsResponse.self, from: data)
        return decoded.listings
    }

    func createListing(_ listing: CreateListingRequest) async throws -> Listing {
        let url = URL(string: "\(baseURL)/listings")!
        let body = try JSONEncoder().encode(listing)
        let request = try await authorizedRequest(url: url, method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(Listing.self, from: data)
    }

    func updateListing(id: String, _ listing: CreateListingRequest) async throws -> Listing {
        let url = URL(string: "\(baseURL)/listings/\(id)")!
        let body = try JSONEncoder().encode(listing)
        let request = try await authorizedRequest(url: url, method: "PUT", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(Listing.self, from: data)
    }

    func updateListingStatus(id: String, status: String) async throws {
        let url = URL(string: "\(baseURL)/listings/\(id)/status")!
        let body = try JSONEncoder().encode(["status": status])
        let request = try await authorizedRequest(url: url, method: "PATCH", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    func deleteListing(id: String) async throws {
        let url = URL(string: "\(baseURL)/listings/\(id)")!
        let request = try await authorizedRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Users

    func upsertProfile(name: String, phone: String?) async throws -> UserProfile {
        let url = URL(string: "\(baseURL)/users/profile")!
        let profileReq = ProfileRequest(name: name, phone: phone, avatarUrl: nil)
        let body = try JSONEncoder().encode(profileReq)
        let request = try await authorizedRequest(url: url, method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func fetchProfile() async throws -> UserProfile {
        let url = URL(string: "\(baseURL)/users/profile")!
        let request = try await authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Неверный ответ сервера"
        case .httpError(let code): return "Ошибка сервера (\(code))"
        }
    }
}
