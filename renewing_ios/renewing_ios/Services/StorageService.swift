import Foundation
import UIKit
import Supabase

class StorageService {
    static let shared = StorageService()

    private let maxDimension: CGFloat = 1200
    private let compressionQuality: CGFloat = 0.7
    private let thumbnailDimension: CGFloat = 400
    private let thumbnailQuality: CGFloat = 0.6

    func uploadPhoto(image: UIImage, userId: String) async throws -> String {
        let imageId = UUID().uuidString

        // Upload full-size and thumbnail in parallel
        async let fullUpload: Void = uploadImage(
            resizeImage(image, maxDimension: maxDimension),
            quality: compressionQuality,
            path: "\(userId)/\(imageId).jpg"
        )
        async let thumbUpload: Void = uploadImage(
            resizeImage(image, maxDimension: thumbnailDimension),
            quality: thumbnailQuality,
            path: "\(userId)/\(imageId)_thumb.jpg"
        )

        _ = try await (fullUpload, thumbUpload)

        let publicURL = try supabase.storage
            .from("listing-photos")
            .getPublicURL(path: "\(userId)/\(imageId).jpg")

        return publicURL.absoluteString
    }

    /// Derive thumbnail URL from a full-size photo URL
    static func thumbnailURL(from photoURL: String) -> String {
        photoURL.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
    }

    private func uploadImage(_ image: UIImage, quality: CGFloat, path: String) async throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageError.compressionFailed
        }

        try await supabase.storage
            .from("listing-photos")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)

        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum StorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Не удалось сжать изображение"
        }
    }
}
