import SwiftUI

struct CategoryFilterBar: View {
    @Binding var selectedCategory: String?

    var body: some View {
        HStack(spacing: 8) {
            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            ForEach(ListingCategory.allCases) { category in
                FilterChip(
                    title: category.displayName,
                    isSelected: selectedCategory == category.rawValue
                ) {
                    selectedCategory = category.rawValue
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.matshareOrange : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
