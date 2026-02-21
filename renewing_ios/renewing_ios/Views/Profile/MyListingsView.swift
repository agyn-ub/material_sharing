import SwiftUI

struct MyListingsView: View {
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingListing: Listing?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if listings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Пока нет объявлений")
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(listings) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.title)
                                    .font(.subheadline.weight(.semibold))

                                HStack {
                                    Text(listing.priceFormatted)
                                        .font(.caption.bold())
                                        .foregroundStyle(listing.isFree == true ? Color.matshareGreen : Color.matshareOrange)

                                    Spacer()

                                    statusBadge(listing.status ?? "active")
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteListing(listing)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }

                            if listing.status == "active" {
                                Button {
                                    markAsSold(listing)
                                } label: {
                                    Label("Продано", systemImage: "checkmark.circle")
                                }
                                .tint(Color.matshareGreen)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingListing = listing
                            } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(Color.matshareOrange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Мои объявления")
        .sheet(item: $editingListing) { listing in
            CreateListingView(editing: listing)
        }
        .task { await loadListings() }
        .refreshable { await loadListings() }
        .onReceive(NotificationCenter.default.publisher(for: .listingCreated)) { _ in
            Task { await loadListings() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .listingUpdated)) { _ in
            Task { await loadListings() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .listingDeleted)) { _ in
            Task { await loadListings() }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .cornerRadius(4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return .green
        case "sold": return .blue
        case "reserved": return .orange
        case "expired": return .gray
        default: return .secondary
        }
    }

    private func loadListings() async {
        isLoading = true
        do {
            listings = try await APIService.shared.fetchMyListings()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func markAsSold(_ listing: Listing) {
        Task {
            try? await APIService.shared.updateListingStatus(id: listing.id, status: "sold")
            await loadListings()
        }
    }

    private func deleteListing(_ listing: Listing) {
        Task {
            try? await APIService.shared.deleteListing(id: listing.id)
            await loadListings()
        }
    }
}
