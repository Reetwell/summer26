import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    private let todayStore = TodayStore.shared
    @State private var showReminders = false
    @State private var notificationsOn = false

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    private var iosLayout: some View {
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

                    // Edit profile + share
                    HStack(spacing: Spacing.sm) {
                        Button {} label: {
                            Text("Edit profile")
                                .font(.sans(14, weight: .bold))
                                .foregroundStyle(Color.green700)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.white, in: Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        Button {} label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.18), in: Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
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
                        Divider().padding(.leading, 52)
                        Button {
                            showReminders = true
                        } label: {
                            HStack(spacing: Spacing.md) {
                                iconBadge("clock.fill", tint: Color(hex: "#E85D9A"))
                                Text("Reminder times").font(.sans(15)).foregroundStyle(.primary)
                                Spacer()
                                Text(todayStore.proteinReminderTime)
                                    .font(.sans(13)).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, Spacing.sm).padding(.vertical, 11).contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        Divider().padding(.leading, 52)
                        Button {
                            #if os(iOS)
                            Task { await HealthKitService.shared.requestAuthorization() }
                            #endif
                        } label: {
                            HStack(spacing: Spacing.md) {
                                iconBadge("heart.fill", tint: Color(hex: "#E8564A"))
                                Text("Apple Health").font(.sans(15)).foregroundStyle(.primary)
                                Spacer()
                                #if os(iOS)
                                Text(HealthKitService.shared.authorized ? "Connected" : "Connect")
                                    .font(.sans(13))
                                    .foregroundStyle(HealthKitService.shared.authorized ? Color.green500 : .secondary)
                                #else
                                Text("iOS only").font(.sans(13)).foregroundStyle(.secondary)
                                #endif
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, Spacing.sm).padding(.vertical, 11).contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .slideIn(delay: 0.13)
                .sheet(isPresented: $showReminders) { remindersSheet }

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
        .hideNavigationBar()
    }

    private var remindersSheet: some View {
        NavigationStack {
            Form {
                Section("Daily reminders") {
                    HStack {
                        Label("Protein check", systemImage: "fork.knife")
                            .font(.sans(15))
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { timeToDate(todayStore.proteinReminderTime) },
                            set: { todayStore.proteinReminderTime = dateToTime($0) }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }
                    HStack {
                        Label("Creatine", systemImage: "pills.fill")
                            .font(.sans(15))
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { timeToDate(todayStore.creatineReminderTime) },
                            set: { todayStore.creatineReminderTime = dateToTime($0) }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }
                    HStack {
                        Label("Hydration", systemImage: "drop.fill")
                            .font(.sans(15))
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { timeToDate(todayStore.waterReminderTime) },
                            set: { todayStore.waterReminderTime = dateToTime($0) }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }
                }
                Section {
                    #if os(iOS)
                    Button("Enable notifications") {
                        Task {
                            await todayStore.requestNotificationPermission()
                            todayStore.saveReminders()
                        }
                    }
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Color.green500)
                    #endif
                } footer: {
                    Text("Reminders send daily at the times you set.")
                        .font(.sans(12))
                }
            }
            .navigationTitle("Reminders")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        todayStore.saveReminders()
                        showReminders = false
                    }
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Color.green500)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReminders = false }
                }
            }
        }
    }

    private func timeToDate(_ s: String) -> Date {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return Date() }
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = parts[0]; c.minute = parts[1]
        return Calendar.current.date(from: c) ?? Date()
    }

    private func dateToTime(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
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

    #if os(macOS)
    // MARK: - macOS: hero banner + overlapping stat cards + 2-column (Stitch)

    private var macLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Green hero banner — rounded, inset card
                HStack(alignment: .top, spacing: Spacing.lg) {
                    Text("RR")
                        .font(.serifDisplay(34))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 92)
                        .background(.white.opacity(0.18), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reece Rothwell")
                            .font(.serifDisplay(40))
                            .foregroundStyle(.white)
                        Text("Member since June 2026")
                            .font(.sans(14))
                            .foregroundStyle(.white.opacity(0.8))
                        HStack(spacing: 8) {
                            heroChip("trophy.fill", "Level 12")
                            heroChip("flame.fill", "6 day streak")
                        }
                        .padding(.top, 6)
                    }
                    Spacer()
                    // Fills the right-side gap with a clear action
                    Button {} label: {
                        HStack(spacing: 7) {
                            Image(systemName: "square.and.pencil").font(.system(size: 13, weight: .semibold))
                            Text("Edit profile").font(.sans(14, weight: .bold))
                        }
                        .foregroundStyle(Color.green700)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(32)
                .padding(.bottom, 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [Color(hex: "#0F7A5C"), Color.green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28)
                )
                .padding(.horizontal, 40)
                .padding(.top, Spacing.md)

                // Overlapping stat cards
                HStack(spacing: 20) {
                    macStatCard("flame.fill", Color(hex: "#E8A13A"), "6", "DAY STREAK")
                    macStatCard("dumbbell.fill", Color(hex: "#4A90D9"), "24", "WORKOUTS")
                    macStatCard("chart.line.downtrend.xyaxis", .green500, "−1.4kg", "THIS MONTH")
                }
                .padding(.horizontal, 64)
                .offset(y: -52)
                .padding(.bottom, -34)

                // Two columns
                HStack(alignment: .top, spacing: 40) {
                    // Settings
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        macSectionHeader("Settings")
                        BBCard(padding: Spacing.xs) {
                            VStack(spacing: 0) {
                                settingsRow(icon: "person.fill", tint: Color(hex: "#4A90D9"), title: "Profile & goals", value: nil)
                                Divider().padding(.leading, 52)
                                settingsRow(icon: "ruler.fill", tint: Color(hex: "#E8A13A"), title: "Units", value: "Metric")
                                Divider().padding(.leading, 52)
                                HStack(spacing: Spacing.md) {
                                    iconBadge("bell.fill", tint: Color(hex: "#8E6FD8"))
                                    Text("Notifications").font(.sans(15))
                                    Spacer()
                                    Toggle("", isOn: $notificationsOn).labelsHidden().tint(.green500)
                                }
                                .padding(.horizontal, Spacing.sm).padding(.vertical, 9)
                                Divider().padding(.leading, 52)
                                settingsRow(icon: "heart.fill", tint: Color(hex: "#E8564A"), title: "Apple Health", value: "Connect")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // More
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        macSectionHeader("More")
                        BBCard(padding: Spacing.xs) {
                            VStack(spacing: 0) {
                                settingsRow(icon: "square.and.arrow.up.fill", tint: Color(hex: "#8E6FD8"), title: "Export my data", value: nil)
                                Divider().padding(.leading, 52)
                                settingsRow(icon: "questionmark.circle.fill", tint: Color(hex: "#E8A13A"), title: "Help & feedback", value: nil)
                                Divider().padding(.leading, 52)
                                settingsRow(icon: "doc.text.fill", tint: .secondary, title: "Terms & privacy", value: nil)
                            }
                        }
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
                        .padding(.top, 4)
                        Text("Build Your Body · v1.0")
                            .font(.sans(11))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(40)
            }
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private func macSectionHeader(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text).font(.serifDisplay(28)).foregroundStyle(Color.green700)
            Divider()
        }
    }

    private func heroChip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(.sans(12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(.white.opacity(0.16), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }

    private func macStatCard(_ icon: String, _ tint: Color, _ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: Circle())
            Text(value).font(.serifDisplay(40)).foregroundStyle(Color.green700)
            Text(label).font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.green900.opacity(0.07), radius: 18, y: 8)
    }
    #endif
}
