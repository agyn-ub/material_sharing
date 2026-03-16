import SwiftUI

struct EULAAcceptanceView: View {
    @EnvironmentObject var appState: AppState
    @State private var accepted = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Пользовательское соглашение")
                        .font(.title2.bold())
                        .padding(.top, 24)

                    Text("Для продолжения использования MatShare, пожалуйста, ознакомьтесь с условиями и примите пользовательское соглашение.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        bulletPoint("Вы несёте ответственность за размещаемый контент")
                        bulletPoint("Запрещена публикация оскорбительного, мошеннического или незаконного содержания")
                        bulletPoint("Пользователи могут жаловаться на нарушения")
                        bulletPoint("Мы вправе удалять контент и блокировать аккаунты нарушителей")
                        bulletPoint("MatShare не является стороной сделок между пользователями")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Link(destination: URL(string: "\(Config.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/terms.html")!) {
                        Text("Читать полное соглашение")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            VStack(spacing: 16) {
                Toggle(isOn: $accepted) {
                    Text("Я принимаю пользовательское соглашение")
                        .font(.subheadline)
                }
                .toggleStyle(.checkbox)

                Button {
                    acceptEULA()
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
                .disabled(!accepted || isLoading)
            }
            .padding()
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }

    private func acceptEULA() {
        isLoading = true
        Task {
            do {
                try await appState.acceptEULA()
            } catch {
                isLoading = false
            }
        }
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.matshareOrange : .secondary)
                    .font(.title3)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}
