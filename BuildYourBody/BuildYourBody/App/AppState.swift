import SwiftUI
import Supabase

@Observable
final class AppState {
    var isAuthenticated = false
    var isLoading = true

    let supabase = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseAnonKey
    )

    init() {
        #if DEBUG
        // Test hook: SIMCTL_CHILD_BB_SKIP_AUTH=1 simctl launch …
        if ProcessInfo.processInfo.environment["BB_SKIP_AUTH"] == "1" {
            isAuthenticated = true
            isLoading = false
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
