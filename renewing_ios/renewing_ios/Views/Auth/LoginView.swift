import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @FocusState private var focusedField: AuthField?

    enum AuthField { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 48)

                // Branding
                VStack(spacing: 10) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.matshareOrange)

                    Text("MatShare")
                        .font(.largeTitle.bold())

                    Text("Делитесь оставшимися материалами\nс людьми поблизости")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Tab switcher
                HStack(spacing: 0) {
                    Button {
                        isSignUp = false
                        errorMessage = nil
                    } label: {
                        Text("Вход")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .foregroundStyle(!isSignUp ? Color.matshareOrange : .secondary)

                    Button {
                        isSignUp = true
                        errorMessage = nil
                    } label: {
                        Text("Регистрация")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .foregroundStyle(isSignUp ? Color.matshareOrange : .secondary)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .overlay(
                    // Underline indicator
                    GeometryReader { geo in
                        Color.matshareOrange
                            .frame(width: geo.size.width / 2, height: 2)
                            .offset(x: isSignUp ? geo.size.width / 2 : 0, y: geo.size.height - 2)
                            .animation(.easeInOut(duration: 0.2), value: isSignUp)
                    }
                )
                .padding(.horizontal, 32)

                // Email/Password fields
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Email", text: $email)
                            .focused($focusedField, equals: .email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding()

                    Divider().padding(.leading, 52)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        SecureField(isSignUp ? "Пароль (мин. 6 символов)" : "Пароль", text: $password)
                            .focused($focusedField, equals: .password)
                            .textContentType(.password)
                    }
                    .padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 32)

                // Submit button
                Button {
                    focusedField = nil
                    submitEmailAuth()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Создать аккаунт" : "Войти")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isEmailFormValid ? Color.matshareOrange : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(!isEmailFormValid || isLoading)
                .padding(.horizontal, 32)

                // Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Divider
                HStack(spacing: 12) {
                    Rectangle().frame(height: 0.5).foregroundStyle(Color(.separator))
                    Text("или")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Rectangle().frame(height: 0.5).foregroundStyle(Color(.separator))
                }
                .padding(.horizontal, 32)

                // Apple Sign-In
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 32)

                Spacer().frame(height: 32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }

    private var isEmailFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6
    }

    private func submitEmailAuth() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if isSignUp {
                    try await authService.signUpWithEmail(email: email.trimmingCharacters(in: .whitespaces), password: password)
                } else {
                    try await authService.signInWithEmail(email: email.trimmingCharacters(in: .whitespaces), password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple credentials"
                return
            }
            Task {
                do {
                    try await authService.signInWithApple(idToken: idToken, nonce: nonce)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
