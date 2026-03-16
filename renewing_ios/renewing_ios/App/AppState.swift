import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var needsProfileSetup = false
    @Published var userProfile: UserProfile?

    var needsEULAAcceptance: Bool {
        userProfile?.eulaAcceptedAt == nil
    }

    func loadProfile() async {
        do {
            let profile = try await APIService.shared.fetchProfile()
            userProfile = profile
            needsProfileSetup = false
        } catch {
            needsProfileSetup = true
        }
    }

    func createProfile(name: String, phone: String?) async throws {
        let profile = try await APIService.shared.upsertProfile(name: name, phone: phone)
        userProfile = profile
        needsProfileSetup = false
    }

    func acceptEULA() async throws {
        guard let name = userProfile?.name else { return }
        let profile = try await APIService.shared.upsertProfile(name: name, phone: userProfile?.phone, eulaAccepted: true)
        userProfile = profile
    }
}
