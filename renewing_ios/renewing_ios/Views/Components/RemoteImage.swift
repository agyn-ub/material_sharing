import SwiftUI
import UIKit

struct RemoteImage: View {
    let url: URL?
    var fallbackURL: URL? = nil
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var isFailed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isFailed {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        image = nil
        isFailed = false

        if let url, let loaded = await fetchImage(from: url) {
            image = loaded
            return
        }
        if let fallbackURL, let loaded = await fetchImage(from: fallbackURL) {
            image = loaded
            return
        }
        isFailed = true
    }

    private func fetchImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let httpResponse = response as? HTTPURLResponse
            print("[RemoteImage] URL: \(url.absoluteString) — status: \(httpResponse?.statusCode ?? -1), bytes: \(data.count)")
            return UIImage(data: data)
        } catch {
            print("[RemoteImage] ERROR loading \(url.absoluteString): \(error)")
            return nil
        }
    }
}
