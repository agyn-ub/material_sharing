import SwiftUI

@main
struct renewing_iosApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appState)
        }
    }
}
