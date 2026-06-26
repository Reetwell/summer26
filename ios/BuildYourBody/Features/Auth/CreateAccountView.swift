import SwiftUI

struct CreateAccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create account")
                            .font(.serifDisplay(28))
                        Text("Start building your body today.")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)

                    BBTextField(label: "Name", placeholder: "Your name", text: $name)
                        .textContentType(.name)

                    BBTextField(label: "Email", placeholder: "you@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    BBTextField(label: "Password", placeholder: "Choose a password", text: $password, isSecure: true)
                        .textContentType(.newPassword)

                    if let error {
                        Text(error)
                            .font(.sans(13))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    BBButton(title: isLoading ? "Creating account…" : "Create account") {
                        Task { await createAccount() }
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.sans(11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.sans(15))
                        .foregroundStyle(.green500)
                }
            }
        }
    }

    private func createAccount() async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            error = "Please fill in all fields."
            return
        }
        isLoading = true
        error = nil
        do {
            try await appState.supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(name)]
            )
            appState.isAuthenticated = true
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
