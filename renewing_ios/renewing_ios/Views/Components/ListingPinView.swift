import SwiftUI

struct ListingPinView: View {
    let listing: Listing
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(listing.priceFormatted)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(pinColor)
                .foregroundStyle(.white)
                .cornerRadius(6)

            // Triangle pointer
            Triangle()
                .fill(pinColor)
                .frame(width: 10, height: 6)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var pinColor: Color {
        if isSelected {
            return .primary
        }
        return (listing.isFree == true) ? Color.matshareGreen : Color.matshareOrange
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
