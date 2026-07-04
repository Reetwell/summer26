import SwiftUI
import Supabase

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
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create account")
                            .font(.custom("DMSerifDisplay-Regular", size: 28))
                        Text("Start building your body today.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                    fieldView(label: "Name", placeholder: "Your name", text: $name)
                        .textContentType(.name)

                    fieldView(label: "Email", placeholder: "you@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    secureFieldView(label: "Password", placeholder: "Choose a password", text: $password)
                        .textContentType(.newPassword)

                    if let error {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await createAccount() }
                    } label: {
                        Text(isLoading ? "Creating account…" : "Create account")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#1D9E75"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#1D9E75"))
                }
            }
        }
    }

    private func fieldView(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }

    private func secureFieldView(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
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
            try await appState.supabase.auth.signUp(email: email, password: password)
            appState.isAuthenticated = true
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
