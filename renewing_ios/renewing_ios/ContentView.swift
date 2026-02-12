import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState

    @State private var showCreateListing = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authService.isLoading {
                ProgressView()
            } else if !authService.isAuthenticated {
                LoginView()
            } else if appState.needsProfileSetup {
                ProfileSetupView(appState: appState)
            } else {
                mainTabView
            }
        }
        .task {
            if authService.isAuthenticated {
                await appState.loadProfile()
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuth in
            if isAuth {
                Task { await appState.loadProfile() }
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            ListingsListView()
                .tabItem {
                    Label("Рядом", systemImage: "location.magnifyingglass")
                }
                .tag(0)

            Text("")
                .tabItem {
                    Label("Разместить", systemImage: "plus.circle.fill")
                }
                .tag(1)

            ProfileView(appState: appState)
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
                .tag(2)
        }
        .tint(Color.matshareOrange)
        .sheet(isPresented: $showCreateListing) {
            CreateListingView()
        }
        .onChange(of: selectedTab) { tab in
            if tab == 1 {
                showCreateListing = true
                selectedTab = 0
            }
        }
    }
}
