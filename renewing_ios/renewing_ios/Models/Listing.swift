import Foundation
import CoreLocation

struct Listing: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let title: String
    let description: String?
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
        case title, description
        case price, currency
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

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
    let price: Double?
    let isFree: Bool
    let photoUrls: [String]
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case title, description, price
        case isFree = "is_free"
        case photoUrls = "photo_urls"
        case latitude, longitude
    }
}
