import SwiftUI
import PhotosUI

extension Notification.Name {
    static let listingCreated = Notification.Name("listingCreated")
    static let listingUpdated = Notification.Name("listingUpdated")
}

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()

    // Edit mode
    let editingListing: Listing?
    private var isEditing: Bool { editingListing != nil }

    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var isFree = false

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var existingPhotoUrls: [String] = []

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    init(editing listing: Listing? = nil) {
        self.editingListing = listing
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo (1 max)
                Section("Фото") {
                    HStack(spacing: 8) {
                        if let urlString = existingPhotoUrls.first {
                            ZStack(alignment: .topTrailing) {
                                RemoteImage(url: URL(string: urlString))
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    .clipped()
                                Button {
                                    existingPhotoUrls.removeAll()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white, .red)
                                }
                                .offset(x: 4, y: -4)
                            }
                        } else if let image = photoImages.first {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    .clipped()
                                Button {
                                    photoImages.removeAll()
                                    selectedPhotos.removeAll()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white, .red)
                                }
                                .offset(x: 4, y: -4)
                            }
                        } else {
                            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.matshareOrange)
                                    Text("Фото")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .onChange(of: selectedPhotos) { items in
                        loadPhotos(items)
                    }
                }

                // Details
                Section("Детали") {
                    TextField("Название", text: $title)

                    TextField("Описание (необязательно)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Price
                Section("Цена") {
                    Toggle("Отдать бесплатно", isOn: $isFree)
                        .tint(Color.matshareGreen)

                    if !isFree {
                        HStack {
                            TextField("Цена", text: $price)
                                .keyboardType(.numberPad)
                            Text("KZT")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Location
                Section("Местоположение") {
                    if let loc = locationService.currentLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.matshareGreen)
                            Text(String(format: "%.4f, %.4f", loc.latitude, loc.longitude))
                                .font(.subheadline)
                        }
                    } else {
                        Button {
                            locationService.requestPermission()
                            locationService.getCurrentLocation()
                        } label: {
                            Label("Использовать текущее местоположение", systemImage: "location.circle")
                        }
                    }

                    if let error = locationService.locationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Редактирование" : "Новое объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Сохранить" : "Разместить") { submitListing() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay { ProgressView(isEditing ? "Сохранение..." : "Публикация...").tint(.white) }
                }
            }
            .alert(isEditing ? "Сохранено!" : "Опубликовано!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text(isEditing ? "Объявление обновлено." : "Ваше объявление теперь видно людям поблизости.")
            }
            .onAppear {
                if let listing = editingListing {
                    prefillFromListing(listing)
                }
                if locationService.currentLocation == nil {
                    locationService.requestPermission()
                    locationService.getCurrentLocation()
                }
            }
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        locationService.currentLocation != nil
    }

    private func prefillFromListing(_ listing: Listing) {
        title = listing.title
        description = listing.description ?? ""
        isFree = listing.isFree ?? false
        if let p = listing.price, p > 0 {
            price = String(format: "%.0f", p)
        }
        existingPhotoUrls = Array((listing.photoUrls ?? []).prefix(1))
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        photoImages = []
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { photoImages.append(image) }
                }
            }
        }
    }

    private func submitListing() {
        guard let location = locationService.currentLocation else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                // Keep existing photos + upload new ones
                var photoUrls: [String] = existingPhotoUrls
                if !photoImages.isEmpty, let userId = AuthService.shared.currentUserId {
                    for image in photoImages {
                        let url = try await StorageService.shared.uploadPhoto(image: image, userId: userId)
                        photoUrls.append(url)
                    }
                }

                let request = CreateListingRequest(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    price: isFree ? 0 : Double(price),
                    isFree: isFree,
                    photoUrls: photoUrls,
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                if isEditing, let listingId = editingListing?.id {
                    _ = try await APIService.shared.updateListing(id: listingId, request)
                    NotificationCenter.default.post(name: .listingUpdated, object: nil)
                } else {
                    _ = try await APIService.shared.createListing(request)
                    NotificationCenter.default.post(name: .listingCreated, object: nil)
                }
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
