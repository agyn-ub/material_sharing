import SwiftUI

struct PriceTag: View {
    let listing: Listing

    var body: some View {
        Text(listing.priceFormatted)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(listing.isFree == true ? Color.matshareGreen : Color.matshareOrange)
            .foregroundStyle(.white)
            .cornerRadius(8)
    }
}
