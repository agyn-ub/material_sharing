import SwiftUI
import PhotosUI

extension Notification.Name {
    static let listingCreated = Notification.Name("listingCreated")
}

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()

    @State private var title = ""
    @State private var description = ""
    @State private var category: ListingCategory = .materials
    @State private var subcategory = ""
    @State private var quantity = ""
    @State private var unit: ListingUnit = .pieces
    @State private var price = ""
    @State private var isFree = true

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                // Photos
                Section("Фото") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: Config.maxPhotosPerListing, matching: .images) {
                        if photoImages.isEmpty {
                            Label("Добавить фото (до \(Config.maxPhotosPerListing))", systemImage: "camera.fill")
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(photoImages.indices, id: \.self) { index in
                                        Image(uiImage: photoImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .clipped()
                                    }
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.matshareOrange)
                                        .frame(width: 80, height: 80)
                                }
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

                    Picker("Категория", selection: $category) {
                        ForEach(ListingCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }

                    Picker("Подкатегория", selection: $subcategory) {
                        Text("Нет").tag("")
                        ForEach(category.subcategories, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                }

                // Quantity & Price
                Section("Количество и цена") {
                    HStack {
                        TextField("Количество", text: $quantity)
                            .keyboardType(.decimalPad)
                        Picker("Ед. изм.", selection: $unit) {
                            ForEach(ListingUnit.allCases) { u in
                                Text(u.displayName).tag(u)
                            }
                        }
                        .labelsHidden()
                    }

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
            .navigationTitle("Новое объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Разместить") { submitListing() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay { ProgressView("Публикация...").tint(.white) }
                }
            }
            .alert("Опубликовано!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Ваше объявление теперь видно людям поблизости.")
            }
            .onAppear {
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
                // Upload photos
                var photoUrls: [String] = []
                if let userId = AuthService.shared.currentUserId {
                    for image in photoImages {
                        let url = try await StorageService.shared.uploadPhoto(image: image, userId: userId)
                        photoUrls.append(url)
                    }
                }

                let request = CreateListingRequest(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    category: category.rawValue,
                    subcategory: subcategory.isEmpty ? nil : subcategory,
                    quantity: Double(quantity),
                    unit: unit.rawValue,
                    price: isFree ? 0 : Double(price),
                    isFree: isFree,
                    photoUrls: photoUrls,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    addressText: nil
                )

                _ = try await APIService.shared.createListing(request)
                NotificationCenter.default.post(name: .listingCreated, object: nil)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
