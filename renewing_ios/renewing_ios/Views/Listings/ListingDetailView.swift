import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    @State private var showFullScreen = false
    @State private var selectedPhotoIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Photos
                if let urls = listing.photoUrls, !urls.isEmpty {
                    TabView(selection: $selectedPhotoIndex) {
                        ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                            RemoteImage(url: URL(string: urlString))
                            .tag(index)
                            .onTapGesture {
                                selectedPhotoIndex = index
                                showFullScreen = true
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 280)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                }

                // Title & price
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.title2.bold())

                    HStack(spacing: 12) {
                        PriceTag(listing: listing)
                        if !listing.distanceFormatted.isEmpty {
                            DistanceBadge(distance: listing.distanceFormatted)
                        }
                        if !listing.category.isEmpty {
                            Text(listing.category.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                // Description
                if let desc = listing.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Описание")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text(desc)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    if let qty = listing.quantity, let unit = listing.unit {
                        DetailRow(icon: "number", label: "Количество", value: "\(String(format: "%.0f", qty)) \(unit)")
                    }
                    if let sub = listing.subcategory {
                        DetailRow(icon: "tag", label: "Подкатегория", value: sub)
                    }
                    if let address = listing.addressText {
                        DetailRow(icon: "mappin", label: "Местоположение", value: address)
                    }
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                // Seller info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Продавец")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    if let name = listing.sellerName {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.body.weight(.medium))
                        }
                    }
                }
                .padding(.horizontal)

                // Action buttons
                VStack(spacing: 10) {
                    if let phone = listing.sellerPhone, !phone.isEmpty {
                        Button {
                            DeepLinks.call(phone: phone)
                        } label: {
                            Label("Позвонить продавцу", systemImage: "phone.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.matshareGreen)
                    }

                    if let lat = listing.latitude, let lng = listing.longitude {
                        Button {
                            DeepLinks.openDirections(lat: lat, lng: lng)
                        } label: {
                            Label("Построить маршрут", systemImage: "map.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.matshareOrange)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                PhotoViewerView(urls: listing.photoUrls ?? [], startIndex: selectedPhotoIndex)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}
