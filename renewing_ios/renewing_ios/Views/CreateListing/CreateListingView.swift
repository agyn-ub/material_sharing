import SwiftUI
import PhotosUI

extension Notification.Name {
    static let listingCreated = Notification.Name("listingCreated")
    static let listingUpdated = Notification.Name("listingUpdated")
}

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()
    @FocusState private var focusedField: Field?

    enum Field { case title, description, price }

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
    @State private var showCancelConfirm = false

    init(editing listing: Listing? = nil) {
        self.editingListing = listing
    }

    private var hasUnsavedChanges: Bool {
        !title.isEmpty || !description.isEmpty || !price.isEmpty || isFree || !photoImages.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Photo
                    photoSection
                        .padding(.horizontal)

                    // Title & Description
                    VStack(spacing: 0) {
                        TextField("Название", text: $title)
                            .focused($focusedField, equals: .title)
                            .padding()

                        Divider().padding(.leading)

                        TextField("Описание (необязательно)", text: $description, axis: .vertical)
                            .focused($focusedField, equals: .description)
                            .lineLimit(3...6)
                            .padding()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Price
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Button {
                                isFree = true
                                focusedField = nil
                            } label: {
                                Text("Бесплатно")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isFree ? Color.matshareGreen : Color(.systemGray5))
                                    .foregroundStyle(isFree ? .white : .primary)
                                    .cornerRadius(10)
                            }

                            Button {
                                isFree = false
                                focusedField = .price
                            } label: {
                                Text("Указать цену")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(!isFree ? Color.matshareOrange : Color(.systemGray5))
                                    .foregroundStyle(!isFree ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }

                        if !isFree {
                            HStack {
                                TextField("0", text: $price)
                                    .focused($focusedField, equals: .price)
                                    .keyboardType(.numberPad)
                                    .font(.title2.weight(.semibold))
                                Text("KZT")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Location
                    HStack {
                        if locationService.currentLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.matshareGreen)
                            Text("Местоположение определено")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if locationService.locationError != nil {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Не удалось определить")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Spacer()
                            Button("Повторить") {
                                locationService.requestPermission()
                                locationService.getCurrentLocation()
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.matshareOrange)
                        } else {
                            ProgressView()
                                .controlSize(.small)
                            Text("Определяем местоположение...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Submit button
                    Button {
                        focusedField = nil
                        submitListing()
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isEditing ? "Сохранить изменения" : "Разместить объявление")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid && !isSubmitting ? Color.matshareOrange : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Редактирование" : "Новое объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        focusedField = nil
                        if hasUnsavedChanges && !isEditing {
                            showCancelConfirm = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
            .confirmationDialog("Отменить создание?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("Удалить черновик", role: .destructive) { dismiss() }
                Button("Продолжить редактирование", role: .cancel) { }
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

    // MARK: - Photo Section

    private var photoSection: some View {
        Group {
            if let urlString = existingPhotoUrls.first {
                ZStack(alignment: .topTrailing) {
                    RemoteImage(url: URL(string: urlString))
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .clipped()
                    Button {
                        existingPhotoUrls.removeAll()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .padding(8)
                    }
                }
            } else if let image = photoImages.first {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .clipped()
                    Button {
                        photoImages.removeAll()
                        selectedPhotos.removeAll()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .padding(8)
                    }
                }
            } else {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundStyle(Color.matshareOrange)
                        Text("Добавить фото")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                            .foregroundStyle(Color(.systemGray3))
                    )
                }
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            loadPhotos(items)
        }
    }

    // MARK: - Logic

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
