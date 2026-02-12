import SwiftUI

struct ListingsListView: View {
    @StateObject private var locationService = LocationService()
    @State private var listings: [Listing] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCategory: String?
    @State private var searchRadius: Double = Double(Config.defaultSearchRadiusMeters)
    @State private var showFilter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterBar(selectedCategory: $selectedCategory)
                    .padding(.vertical, 8)

                if showFilter {
                    radiusSlider
                }

                if isLoading && listings.isEmpty {
                    Spacer()
                    ProgressView("Поиск объявлений поблизости...")
                    Spacer()
                } else if let errorMessage {
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
                } else if listings.isEmpty {
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
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    ListingCardView(listing: listing)
                                }
                                .buttonStyle(.plain)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showFilter.toggle() }
                    } label: {
                        Image(systemName: showFilter ? "slider.horizontal.3" : "slider.horizontal.3")
                            .foregroundStyle(showFilter ? Color.matshareOrange : .primary)
                    }
                }
            }
            .onAppear {
                if locationService.authorizationStatus == .notDetermined {
                    locationService.requestPermission()
                } else {
                    locationService.getCurrentLocation()
                }
            }
            .onChange(of: locationService.currentLocation) { location in
                if location != nil { loadListings() }
            }
            .onChange(of: selectedCategory) { _ in loadListings() }
            .onReceive(NotificationCenter.default.publisher(for: .listingCreated)) { _ in
                loadListings()
            }
        }
    }

    private var radiusSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Радиус поиска")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(String(format: "%.0f", searchRadius / 1000)) km")
                    .font(.caption.bold())
            }
            Slider(value: $searchRadius, in: 1000...Double(Config.maxSearchRadiusMeters), step: 1000)
                .tint(Color.matshareOrange)
                .onChange(of: searchRadius) { _ in loadListings() }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func loadListings() {
        guard let location = locationService.currentLocation else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                listings = try await APIService.shared.fetchNearbyListings(
                    lat: location.latitude,
                    lng: location.longitude,
                    radius: Int(searchRadius),
                    category: selectedCategory
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
