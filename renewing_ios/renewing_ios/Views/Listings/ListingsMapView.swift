import SwiftUI
import MapKit

struct ListingsMapView: View {
    let listings: [Listing]
    @ObservedObject var locationService: LocationService
    let searchRadius: Double
    let onSelectListing: (Listing) -> Void

    @State private var region: MKCoordinateRegion = .init()
    @State private var selectedListing: Listing?
    @State private var hasSetInitialRegion = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: mappableListings) { listing in
                MapAnnotation(coordinate: listing.coordinate!) {
                    ListingPinView(listing: listing, isSelected: selectedListing?.id == listing.id)
                        .onTapGesture {
                            withAnimation {
                                selectedListing = listing
                            }
                        }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Re-center button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        recenter()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.body)
                            .padding(10)
                            .background(.ultraThickMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            .padding(.top, 8)

            // Bottom card
            if let selected = selectedListing {
                ListingMapCard(listing: selected)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .onTapGesture {
                        onSelectListing(selected)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onTapGesture {
            withAnimation {
                selectedListing = nil
            }
        }
        .onAppear {
            if !hasSetInitialRegion {
                recenter()
                hasSetInitialRegion = true
            }
        }
        .onChange(of: locationService.currentLocation) { _, _ in
            if !hasSetInitialRegion {
                recenter()
                hasSetInitialRegion = true
            }
        }
    }

    private var mappableListings: [Listing] {
        listings.filter { $0.coordinate != nil }
    }

    private func recenter() {
        guard let location = locationService.currentLocation else { return }
        let spanDegrees = searchRadius / 111_000 * 1.5 // ~111km per degree, with padding
        withAnimation {
            region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
            )
        }
    }
}
