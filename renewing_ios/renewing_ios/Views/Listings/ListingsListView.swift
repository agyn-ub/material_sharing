import SwiftUI

struct ListingsListView: View {
    @StateObject private var locationService = LocationService()
    @State private var listings: [Listing] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchRadius: Double = Double(Config.defaultSearchRadiusMeters)
    @State private var selectedCategory: String?
    @State private var showFilter = false
    @State private var hasMore = true
    @State private var loadGeneration = 0

    private let pageSize = 10

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading && listings.isEmpty {
                    Spacer()
                    ProgressView("Поиск объявлений поблизости...")
                    Spacer()
                } else if let errorMessage, listings.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Повторить") { loadListings() }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if listings.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Нет объявлений поблизости")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(listings) { listing in
                                NavigationLink(value: listing) {
                                    ListingCardView(listing: listing)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if listing.id == listings.last?.id {
                                        loadMore()
                                    }
                                }
                            }
                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    .refreshable { loadListings() }
                }
            }
            .background(Color.matshareBg)
            .navigationTitle("MatShare")
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(listing: listing)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(hasActiveFilters ? Color.matshareOrange : .primary)
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                FilterSheet(
                    selectedCategory: $selectedCategory,
                    searchRadius: $searchRadius,
                    onApply: { loadListings() }
                )
                .presentationDetents([.medium])
            }
            .onAppear {
                if locationService.authorizationStatus == .notDetermined {
                    locationService.requestPermission()
                } else if locationService.currentLocation == nil {
                    locationService.getCurrentLocation()
                }
            }
            .onChange(of: locationService.currentLocation) { location in
                if location != nil && listings.isEmpty { loadListings() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .listingCreated)) { _ in
                loadListings()
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || searchRadius != Double(Config.defaultSearchRadiusMeters)
    }

    private func loadListings() {
        guard let location = locationService.currentLocation else { return }
        isLoading = true
        errorMessage = nil
        hasMore = true
        loadGeneration += 1
        let gen = loadGeneration
        Task {
            do {
                let results = try await APIService.shared.fetchNearbyListings(
                    lat: location.latitude,
                    lng: location.longitude,
                    radius: Int(searchRadius),
                    category: selectedCategory,
                    limit: pageSize,
                    offset: 0
                )
                guard gen == loadGeneration else { return }
                listings = results
                hasMore = results.count == pageSize
            } catch {
                guard gen == loadGeneration else { return }
                if listings.isEmpty {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }

    private func loadMore() {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        guard let location = locationService.currentLocation else { return }
        isLoadingMore = true
        let gen = loadGeneration
        Task {
            do {
                let results = try await APIService.shared.fetchNearbyListings(
                    lat: location.latitude,
                    lng: location.longitude,
                    radius: Int(searchRadius),
                    category: selectedCategory,
                    limit: pageSize,
                    offset: listings.count
                )
                guard gen == loadGeneration else { return }
                listings.append(contentsOf: results)
                hasMore = results.count == pageSize
            } catch {
                // Silent fail on pagination — user can pull to refresh
            }
            isLoadingMore = false
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedCategory: String?
    @Binding var searchRadius: Double
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Категория")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        FilterChip(title: "Все", isSelected: selectedCategory == nil) {
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
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Радиус поиска")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack {
                        Slider(value: $searchRadius, in: 1000...Double(Config.maxSearchRadiusMeters), step: 1000)
                            .tint(Color.matshareOrange)
                        Text("\(String(format: "%.0f", searchRadius / 1000)) км")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 50, alignment: .trailing)
                    }
                }

                Spacer()

                Button {
                    onApply()
                    dismiss()
                } label: {
                    Text("Применить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.matshareOrange)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сбросить") {
                        selectedCategory = nil
                        searchRadius = Double(Config.defaultSearchRadiusMeters)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.matshareOrange)
                }
            }
        }
    }
}
