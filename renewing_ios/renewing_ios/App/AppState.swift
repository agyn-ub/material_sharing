import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var needsProfileSetup = false
    @Published var userProfile: UserProfile?

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
}
