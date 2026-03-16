import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String?
    let avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?
    let eulaAcceptedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case eulaAcceptedAt = "eula_accepted_at"
    }
}

struct ProfileRequest: Codable {
    let name: String
    let phone: String?
    let avatarUrl: String?
    let eulaAccepted: Bool?

    enum CodingKeys: String, CodingKey {
        case name, phone
        case avatarUrl = "avatar_url"
        case eulaAccepted = "eula_accepted_at"
    }
}
