import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String?
    let avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProfileRequest: Codable {
    let name: String
    let phone: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, phone
        case avatarUrl = "avatar_url"
    }
}
