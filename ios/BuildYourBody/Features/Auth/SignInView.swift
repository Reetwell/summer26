import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var email    = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCreate = false

    var body: some View {
        ZStack {
            // Green hero background
            LinearGradient(
                colors: [Color.green700, Color.green900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Noise/texture overlay — subtle depth
            Rectangle()
                .fill(.black.opacity(0.08))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Brand wordmark
                HStack {
                    Text("Build Your Body")
                        .font(.serifDisplay(18))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xxl)

                Spacer()

                // Form sheet
                VStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.serifDisplay(32))
                        Text("Sign in to pick up where you left off.")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)

                    // Social sign-in
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                    // Divider
                    HStack {
                        Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
                        Text("or").font(.sans(12)).foregroundStyle(.tertiary)
                        Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
                    }

                    BBTextField(label: "Email", placeholder: "you@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    BBTextField(label: "Password", placeholder: "••••••••", text: $password, isSecure: true)
                        .textContentType(.password)

                    if let error {
                        Text(error)
                            .font(.sans(13))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    BBButton(title: isLoading ? "Signing in…" : "Sign in") {
                        Task { await signIn() }
                    }

                    HStack {
                        Text("New here?")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                        Button("Create account") { showCreate = true }
                            .font(.sans(14, weight: .semibold))
                            .foregroundStyle(.green500)
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.sans(11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.xl)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateAccountView()
        }
    }

    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter your email and password."
            return
        }
        isLoading = true
        error = nil
        do {
            try await appState.supabase.auth.signIn(email: email, password: password)
            appState.isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }
            Task {
                do {
                    try await appState.supabase.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: token)
                    )
                    appState.isAuthenticated = true
                } catch {
                    self.error = error.localizedDescription
                }
            }
        case .failure(let err):
            self.error = err.localizedDescription
        }
    }
}
