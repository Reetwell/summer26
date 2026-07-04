import SwiftUI
import Supabase

@Observable
final class AppState {
    var isAuthenticated = false
    var isLoading = true
    var hasOnboarded = UserDefaults.standard.bool(forKey: "bb-onboarded")

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "bb-onboarded")
        hasOnboarded = true
    }

    let supabase = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseAnonKey
    )

    init() {
        #if DEBUG
        // Test hooks: SIMCTL_CHILD_BB_SKIP_AUTH=1 / BB_FORCE_ONBOARDING=1
        if ProcessInfo.processInfo.environment["BB_FORCE_ONBOARDING"] == "1" {
            hasOnboarded = false
        }
        if ProcessInfo.processInfo.environment["BB_SKIP_AUTH"] == "1" {
            isAuthenticated = true
            isLoading = false
            if ProcessInfo.processInfo.environment["BB_FORCE_ONBOARDING"] != "1" {
                hasOnboarded = true
            }
            return
        }
        #endif
        Task { await checkSession() }
    }

    func checkSession() async {
        do {
            _ = try await supabase.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
    }
}
