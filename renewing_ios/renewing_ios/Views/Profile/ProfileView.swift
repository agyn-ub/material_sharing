import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: AppState
    @State private var showEditName = false
    @State private var showEditPhone = false
    @State private var editName = ""
    @State private var editPhone = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.matshareOrange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.userProfile?.name ?? "User")
                                .font(.headline)
                            if let phone = appState.userProfile?.phone {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Мои объявления") {
                    NavigationLink(destination: MyListingsView()) {
                        Label("Мои объявления", systemImage: "list.bullet")
                    }
                }

                Section("Аккаунт") {
                    Button {
                        editName = appState.userProfile?.name ?? ""
                        editPhone = appState.userProfile?.phone ?? ""
                        showEditName = true
                    } label: {
                        Label("Редактировать профиль", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        Task {
                            try? await AuthService.shared.signOut()
                        }
                    } label: {
                        Label("Выйти", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Профиль")
            .alert("Редактировать профиль", isPresented: $showEditName) {
                TextField("Имя", text: $editName)
                TextField("Телефон", text: $editPhone)
                Button("Сохранить") {
                    Task {
                        try? await appState.createProfile(
                            name: editName,
                            phone: editPhone.isEmpty ? nil : editPhone
                        )
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}
