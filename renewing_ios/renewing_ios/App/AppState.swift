import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var needsProfileSetup = false
    @Published var userProfile: UserProfile?
    @Published var eulaAccepted = false
    @Published var isLoaded = false

    var needsEULAAcceptance: Bool {
        guard isLoaded else { return false }
        // Already accepted in DB
        if userProfile?.eulaAcceptedAt != nil { return false }
        // Accepted locally this session (will be saved with profile)
        if eulaAccepted { return false }
        return true
    }

    func loadProfile() async {
        do {
            let profile = try await APIService.shared.fetchProfile()
            userProfile = profile
            needsProfileSetup = false
        } catch let error as APIError {
            if case .httpError(let code) = error, code == 401 {
                try? await AuthService.shared.signOut()
                return
            }
            needsProfileSetup = true
        } catch {
            needsProfileSetup = true
        }
        isLoaded = true
    }

    func acceptEULA() async throws {
        if let profile = userProfile {
            // Existing user — save to DB immediately
            let updated = try await APIService.shared.upsertProfile(name: profile.name, phone: profile.phone, eulaAccepted: true)
            userProfile = updated
        }
        // Mark accepted locally (for new users, saved when profile is created)
        eulaAccepted = true
    }

    func createProfile(name: String, phone: String?) async throws {
        let profile = try await APIService.shared.upsertProfile(name: name, phone: phone, eulaAccepted: true)
        userProfile = profile
        needsProfileSetup = false
    }
}
