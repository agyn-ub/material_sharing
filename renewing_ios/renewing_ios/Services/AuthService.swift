import Foundation
import AuthenticationServices
import Supabase
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var isLoading = true

    private init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id.uuidString
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUserId = nil
        }
        isLoading = false
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        currentUserId = session.user.id.uuidString
        isAuthenticated = true
    }

    func getAccessToken() async throws -> String {
        let session = try await supabase.auth.session
        return session.accessToken
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        isAuthenticated = false
        currentUserId = nil
    }
}
