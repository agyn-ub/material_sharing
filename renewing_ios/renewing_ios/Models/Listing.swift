import Foundation

struct Listing: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let description: String?
    let category: String
    let subcategory: String?
    let quantity: Double?
    let unit: String?
    let price: Double?
    let currency: String?
    let isFree: Bool?
    let photoUrls: [String]?
    let addressText: String?
    let status: String?
    let createdAt: String?
    let distanceMeters: Double?
    let sellerName: String?
    let sellerPhone: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, description, category, subcategory
        case quantity, unit, price, currency
        case isFree = "is_free"
        case photoUrls = "photo_urls"
        case addressText = "address_text"
        case status
        case createdAt = "created_at"
        case distanceMeters = "distance_meters"
        case sellerName = "seller_name"
        case sellerPhone = "seller_phone"
        case latitude, longitude
    }

    var distanceFormatted: String {
        guard let meters = distanceMeters else { return "" }
        if meters < 1000 {
            return "\(Int(meters)) м"
        }
        let km = String(format: "%.1f", meters / 1000)
        return "\(km) км"
    }

    var priceFormatted: String {
        if isFree == true || price == nil || price == 0 {
            return "Бесплатно"
        }
        let formatted = String(format: "%.0f", price!)
        return "\(formatted) \(currency ?? "KZT")"
    }

    var firstPhotoURL: URL? {
        guard let urls = photoUrls, let first = urls.first else { return nil }
        return URL(string: first)
    }

    var firstThumbnailURL: URL? {
        guard let urls = photoUrls, let first = urls.first else { return nil }
        return URL(string: StorageService.thumbnailURL(from: first))
    }
}

struct ListingsResponse: Codable {
    let listings: [Listing]
    let total: Int?
}

struct CreateListingRequest: Codable {
    let title: String
    let description: String?
    let category: String
    let subcategory: String?
    let quantity: Double?
    let unit: String?
    let price: Double?
    let isFree: Bool
    let photoUrls: [String]
    let latitude: Double
    let longitude: Double
    let addressText: String?

    enum CodingKeys: String, CodingKey {
        case title, description, category, subcategory
        case quantity, unit, price
        case isFree = "is_free"
        case photoUrls = "photo_urls"
        case latitude, longitude
        case addressText = "address_text"
    }
}
