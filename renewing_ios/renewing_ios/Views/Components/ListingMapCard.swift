import SwiftUI

struct ListingMapCard: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: listing.firstThumbnailURL, fallbackURL: listing.firstPhotoURL)
                .frame(width: 70, height: 70)
                .cornerRadius(10)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

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
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
