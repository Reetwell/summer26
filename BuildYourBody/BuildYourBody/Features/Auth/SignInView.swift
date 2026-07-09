import SwiftUI
import AuthenticationServices
import Supabase
import Combine

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var email    = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCreate = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSize
    #endif

    var body: some View {
        Group {
            #if os(macOS)
            splitLayout
            #else
            // iPad (regular width) gets the split screen; iPhone gets the sheet
            if hSize == .regular { splitLayout } else { sheetLayout }
            #endif
        }
        .sheet(isPresented: $showCreate) {
            CreateAccountView()
        }
    }

    // MARK: - Split screen (macOS + iPad): form left / brand panel right

    private var splitLayout: some View {
        HStack(spacing: 0) {
            // LEFT — form on cream
            ZStack(alignment: .topLeading) {
                Color.bbBackground.ignoresSafeArea()

                // Brand wordmark pinned top-left
                (Text("Build Your ").foregroundStyle(.primary)
                 + Text("Body").foregroundStyle(Color.green500))
                    .font(.serifDisplay(19))
                    .padding(.top, 34)
                    .padding(.leading, 44)

                // Centered form
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome back")
                            .font(.serifDisplay(34))
                        Text("Sign in to pick up where you left off.")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, Spacing.sm)

                    socialButtons
                    orDivider
                    formFields

                    BBButton(title: isLoading ? "Signing in…" : "Sign in") {
                        Task { await signIn() }
                    }

                    HStack(spacing: 4) {
                        Text("New here?")
                            .font(.sans(13))
                            .foregroundStyle(.secondary)
                        Button("Create account") { showCreate = true }
                            .buttonStyle(.plain)
                            .font(.sans(13, weight: .semibold))
                            .foregroundStyle(Color.green500)
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.sans(11))
                        .foregroundStyle(.tertiary)

                    #if DEBUG
                    Button("Skip sign-in (dev) →") {
                        appState.isAuthenticated = true
                    }
                    .buttonStyle(.plain)
                    .font(.sans(12))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                    #endif
                }
                .frame(maxWidth: 360)
                .padding(.horizontal, 44)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(width: 460)

            // RIGHT — green brand panel with word reel
            BrandPanelView()
        }
        .ignoresSafeArea()
    }

    // MARK: - iOS: sheet over green hero

    #if os(iOS)
    private var sheetLayout: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green700, Color.green900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(.black.opacity(0.08))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Build Your Body")
                        .font(.serifDisplay(18))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xxl)

                Spacer()

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

                    socialButtons
                    orDivider
                    formFields

                    BBButton(title: isLoading ? "Signing in…" : "Sign in") {
                        Task { await signIn() }
                    }

                    HStack {
                        Text("New here?")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                        Button("Create account") { showCreate = true }
                            .font(.sans(14, weight: .semibold))
                            .foregroundStyle(Color.green500)
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.sans(11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)

                    #if DEBUG
                    Button("Skip sign-in (dev)") {
                        appState.isAuthenticated = true
                    }
                    .font(.sans(12))
                    .foregroundStyle(.tertiary)
                    .padding(.top, Spacing.xs)
                    #endif
                }
                .padding(Spacing.xl)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
    #endif

    // MARK: - shared pieces

    private var socialButtons: some View {
        VStack(spacing: Spacing.sm) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 46)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            Button {
                // TODO: Google OAuth via Supabase (needs redirect URL config)
            } label: {
                HStack(spacing: 8) {
                    Text("G")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(hex: "#4285F4"), Color(hex: "#EA4335")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Continue with Google")
                        .font(.sans(14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var orDivider: some View {
        HStack {
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
            Text("or").font(.sans(12)).foregroundStyle(.tertiary)
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
        }
    }

    private var formFields: some View {
        VStack(spacing: Spacing.md) {
            BBTextField(label: "Email", placeholder: "you@email.com", text: $email)
                .textContentType(.emailAddress)
                .emailKeyboard()
                .autocorrectionDisabled()

            BBTextField(label: "Password", placeholder: "••••••••", text: $password, isSecure: true)
                .textContentType(.password)

            if let error {
                Text(error)
                    .font(.sans(13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - actions

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

// MARK: - Brand panel: green gradient, floating orbs, word reel (web parity)

private struct BrandPanelView: View {
    private let words = ["Train.", "Eat.", "Track.", "Build."]
    @State private var index = 0
    @State private var orbShift = false

    private let timer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green500, Color.green900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft floating orbs — slow drift
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: orbShift ? -160 : -120, y: orbShift ? -220 : -180)
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: orbShift ? 180 : 140, y: orbShift ? 240 : 200)

            // Word reel
            ZStack {
                Text(words[index])
                    .font(.serifDisplay(84))
                    .foregroundStyle(.white)
                    .id(index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            .clipped()

            // Brand footer — glass chip
            VStack {
                Spacer()
                HStack(spacing: 7) {
                    Circle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Text("Build Your Body")
                        .font(.sans(13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: Capsule())
                .padding(.bottom, 30)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                index = (index + 1) % words.count
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                orbShift = true
            }
        }
    }
}
