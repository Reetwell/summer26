import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if !appState.isAuthenticated {
                SignInView()
            } else if !appState.hasOnboarded {
                OnboardingView {
                    appState.completeOnboarding()
                }
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appState.hasOnboarded)
    }
}
