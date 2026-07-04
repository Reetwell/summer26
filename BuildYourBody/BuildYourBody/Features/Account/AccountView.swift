import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    @State private var notificationsOn = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Account")
                    .font(.serifDisplay(34))
                    .slideIn()

                // Green hero — mirrors the web account signin-card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        Text("RR")
                            .font(.serifDisplay(22))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(.white.opacity(0.18), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Reece Rothwell")
                                .font(.serifDisplay(20))
                                .foregroundStyle(.white)
                            Text("Member since June 2026")
                                .font(.sans(12))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                    }

                    HStack(spacing: Spacing.sm) {
                        heroStat(value: "6", label: "day streak")
                        heroStat(value: "24", label: "workouts")
                        heroStat(value: "-1.4kg", label: "this month")
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.green500, .green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )
                .slideIn(delay: 0.06)

                // Settings
                sectionLabel("SETTINGS")
                    .slideIn(delay: 0.1)

                BBCard(padding: Spacing.xs) {
                    VStack(spacing: 0) {
                        settingsRow(icon: "person.fill", tint: .green500, title: "Profile & goals")
                        Divider().padding(.leading, 52)
                        settingsRow(icon: "ruler.fill", tint: Color(hex: "#4A90D9"), title: "Units", value: "Metric")
                        Divider().padding(.leading, 52)
                        HStack(spacing: Spacing.md) {
                            iconBadge("bell.fill", tint: Color(hex: "#E85D9A"))
                            Text("Notifications")
                                .font(.sans(15))
                            Spacer()
                            Toggle("", isOn: $notificationsOn)
                                .labelsHidden()
                                .tint(.green500)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 9)
                        Divider().padding(.leading, 52)
                        settingsRow(icon: "heart.fill", tint: Color(hex: "#E8564A"), title: "Apple Health", value: "Connect")
                    }
                }
                .slideIn(delay: 0.13)

                // More
                sectionLabel("MORE")
                    .slideIn(delay: 0.17)

                BBCard(padding: Spacing.xs) {
                    VStack(spacing: 0) {
                        settingsRow(icon: "square.and.arrow.up.fill", tint: Color(hex: "#8E6FD8"), title: "Export my data")
                        Divider().padding(.leading, 52)
                        settingsRow(icon: "questionmark.circle.fill", tint: Color(hex: "#E8A13A"), title: "Help & feedback")
                        Divider().padding(.leading, 52)
                        settingsRow(icon: "doc.text.fill", tint: .secondary, title: "Terms & privacy")
                    }
                }
                .slideIn(delay: 0.2)

                // Sign out
                Button {
                    Task { await appState.signOut() }
                } label: {
                    Text("Sign out")
                        .font(.sans(15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#E8564A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
                }
                .buttonStyle(ScaleButtonStyle())
                .slideIn(delay: 0.24)

                Text("Build Your Body · v1.0")
                    .font(.sans(11))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .slideIn(delay: 0.28)
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.serifDisplay(18))
                .foregroundStyle(.white)
            Text(label)
                .font(.sans(11))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.sans(11, weight: .semibold))
            .foregroundStyle(.secondary)
            .kerning(1.2)
            .padding(.top, 4)
    }

    private func iconBadge(_ systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.sm))
    }

    private func settingsRow(icon: String, tint: Color, title: String, value: String? = nil) -> some View {
        Button {} label: {
            HStack(spacing: Spacing.md) {
                iconBadge(icon, tint: tint)
                Text(title)
                    .font(.sans(15))
                    .foregroundStyle(.primary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
