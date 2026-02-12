import SwiftUI

struct DistanceBadge: View {
    let distance: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.caption2)
            Text(distance)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
