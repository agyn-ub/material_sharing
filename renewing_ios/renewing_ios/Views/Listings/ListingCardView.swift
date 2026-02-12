import SwiftUI

struct ListingCardView: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 12) {
            // Photo
            AsyncImage(url: listing.firstThumbnailURL ?? listing.firstPhotoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                default:
                    Color(.systemGray5)
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                if let qty = listing.quantity, let unit = listing.unit {
                    Text("\(String(format: "%.0f", qty)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    PriceTag(listing: listing)
                    if !listing.distanceFormatted.isEmpty {
                        DistanceBadge(distance: listing.distanceFormatted)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
