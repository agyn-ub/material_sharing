import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var appState: AppState
    @State private var name = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Настройте свой профиль")
                    .font(.title2.bold())

                Text("Введите имя и телефон, чтобы покупатели могли с вами связаться")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    TextField("Ваше имя", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)

                    TextField("Номер телефона (необязательно)", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    saveProfile()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Продолжить")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.matshareOrange)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarBackButtonHidden()
        }
    }

    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appState.createProfile(
                    name: name.trimmingCharacters(in: .whitespaces),
                    phone: phone.isEmpty ? nil : phone
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
