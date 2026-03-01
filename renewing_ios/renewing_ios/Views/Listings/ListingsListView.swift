import SwiftUI

struct ListingsListView: View {
    @StateObject private var locationService = LocationService()
    @State private var listings: [Listing] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchRadius: Double = Double(Config.defaultSearchRadiusMeters)
    @State private var searchText = ""
    @State private var showFilter = false
    @State private var hasMore = true
    @State private var loadGeneration = 0
    @State private var hasLoadedOnce = false
    @State private var showMap = false
    @State private var mapListings: [Listing] = []
    @State private var isLoadingMapListings = false
    @State private var navigationPath = NavigationPath()

    private let pageSize = 6
    private let mapPageSize = 50

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if showMap {
                    if isLoading && listings.isEmpty {
                        ProgressView("Поиск объявлений поблизости...")
                    } else {
                        ListingsMapView(
                            listings: mapListings.isEmpty ? listings : mapListings,
                            locationService: locationService,
                            searchRadius: searchRadius
                        ) { listing in
                            navigationPath.append(listing)
                        }
                    }
                } else {
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
                        } else if listings.isEmpty && !isLoading && hasLoadedOnce {
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
                        } else if listings.isEmpty && !isLoading && !hasLoadedOnce {
                            Spacer()
                            ProgressView("Поиск объявлений поблизости...")
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
                }
            }
            .overlay {
                if isLoading && !listings.isEmpty {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.6))
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("MatShare")
            .searchable(text: $searchText, prompt: "Поиск по названию")
            .onSubmit(of: .search) { loadListings() }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty { loadListings() }
            }
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(listing: listing)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMap.toggle()
                        if showMap && mapListings.isEmpty {
                            loadMapListings()
                        }
                    } label: {
                        Image(systemName: showMap ? "list.bullet" : "map")
                    }
                }
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
                } else {
                    loadListings()
                }
            }
            .onChange(of: locationService.currentLocation) { _, location in
                if location != nil { loadListings() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .listingCreated)) { _ in
                loadListings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .listingUpdated)) { _ in
                loadListings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .listingDeleted)) { _ in
                loadListings()
            }
        }
    }

    private var hasActiveFilters: Bool {
        searchRadius != Double(Config.defaultSearchRadiusMeters) || !searchText.isEmpty
    }

    private func loadListings() {
        guard let location = locationService.currentLocation else { return }
        isLoading = true
        errorMessage = nil
        hasMore = true
        mapListings = []
        loadGeneration += 1
        let gen = loadGeneration
        Task {
            do {
                let results = try await APIService.shared.fetchNearbyListings(
                    lat: location.latitude,
                    lng: location.longitude,
                    radius: Int(searchRadius),
                    search: searchText.isEmpty ? nil : searchText,
                    limit: pageSize,
                    offset: 0
                )
                guard gen == loadGeneration else { return }
                listings = results
                hasMore = results.count == pageSize
                hasLoadedOnce = true
                if showMap { loadMapListings() }
            } catch {
                guard gen == loadGeneration else { return }
                hasLoadedOnce = true
                if listings.isEmpty {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }

    private func loadMapListings() {
        guard let location = locationService.currentLocation else { return }
        isLoadingMapListings = true
        Task {
            do {
                let results = try await APIService.shared.fetchNearbyListings(
                    lat: location.latitude,
                    lng: location.longitude,
                    radius: Int(searchRadius),
                    search: searchText.isEmpty ? nil : searchText,
                    limit: mapPageSize,
                    offset: 0
                )
                mapListings = results
            } catch {
                // Fall back to existing listings on error
            }
            isLoadingMapListings = false
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
                    search: searchText.isEmpty ? nil : searchText,
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
    @Binding var searchRadius: Double
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
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
                        searchRadius = Double(Config.defaultSearchRadiusMeters)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.matshareOrange)
                }
            }
        }
    }
}
