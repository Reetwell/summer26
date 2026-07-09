import SwiftUI

struct ReadinessCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    private let store = ReadinessStore.shared

    @State private var sleep = 3
    @State private var energy = 3
    @State private var soreness = 3
    @State private var source = "manual"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How are you feeling?")
                            .font(.serifDisplay(32))
                        Text("Rate each on 1 (worst) → 5 (best)")
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                    .slideIn()

                    // Sleep row
                    ratingRow(
                        icon: "moon.zzz.fill", color: Color(hex: "#6B7FD4"),
                        title: "Sleep quality",
                        hint: sleepHint,
                        value: $sleep
                    )
                    .slideIn(delay: 0.06)

                    // Energy row
                    ratingRow(
                        icon: "bolt.fill", color: Color(hex: "#E8A13A"),
                        title: "Energy level",
                        hint: energyHint,
                        value: $energy
                    )
                    .slideIn(delay: 0.12)

                    // Soreness row — inverted (5 = no soreness = good)
                    ratingRow(
                        icon: "figure.strengthtraining.traditional", color: Color.green500,
                        title: "Muscle soreness",
                        hint: sorenessHint,
                        value: $soreness,
                        invertLabel: true
                    )
                    .slideIn(delay: 0.18)

                    // Preview score
                    let preview = Int(Double(sleep + energy + (6 - soreness)) / 15.0 * 100)
                    BBCard {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle().stroke(Color.green500.opacity(0.15), lineWidth: 6)
                                Circle()
                                    .trim(from: 0, to: CGFloat(preview) / 100)
                                    .stroke(Color.green500, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("\(preview)")
                                    .font(.serifDisplay(22))
                                    .contentTransition(.numericText())
                            }
                            .frame(width: 60, height: 60)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: preview)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Readiness score")
                                    .font(.sans(15, weight: .semibold))
                                Text(labelFor(preview))
                                    .font(.sans(13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .slideIn(delay: 0.24)

                    #if os(iOS)
                    if let hk = healthKitNote {
                        Label(hk, systemImage: "heart.fill")
                            .font(.sans(12))
                            .foregroundStyle(Color(hex: "#E05C5C"))
                            .slideIn(delay: 0.28)
                    }
                    #endif
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.bbBackground)
            .navigationTitle("Daily check-in")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.sans(15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.save(sleep: sleep, energy: energy, soreness: soreness, source: source)
                        dismiss()
                    }
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Color.green500)
                }
            }
        }
        .task { await loadHealthKit() }
    }

    // MARK: - Rating row

    private func ratingRow(icon: String, color: Color, title: String, hint: String, value: Binding<Int>, invertLabel: Bool = false) -> some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.sans(15, weight: .semibold))
                        Text(hint).font(.sans(12)).foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { value.wrappedValue = i }
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(i <= value.wrappedValue ? color : Color.secondary.opacity(0.15))
                                    .frame(height: 36)
                                    .overlay(
                                        Text("\(i)")
                                            .font(.sans(14, weight: .semibold))
                                            .foregroundStyle(i <= value.wrappedValue ? .white : .secondary)
                                    )
                                Text(invertLabel ? invertedPipLabel(i) : pipLabel(i))
                                    .font(.sans(9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func pipLabel(_ i: Int) -> String {
        switch i { case 1: return "Poor"; case 2: return "Low"; case 3: return "OK"; case 4: return "Good"; default: return "Great" }
    }

    private func invertedPipLabel(_ i: Int) -> String {
        switch i { case 1: return "Very sore"; case 2: return "Sore"; case 3: return "Mild"; case 4: return "Light"; default: return "Fresh" }
    }

    private func labelFor(_ score: Int) -> String {
        switch score {
        case 80...: return "Recovered — good day to push."
        case 60..<80: return "Moderate — solid but listen to your body."
        default: return "Take it easy — rest or light session."
        }
    }

    // MARK: - Hints from current value

    private var sleepHint: String {
        switch sleep { case 1: return "< 5 hours"; case 2: return "5–6 hours"; case 3: return "6–7 hours"; case 4: return "7–8 hours"; default: return "8+ hours" }
    }
    private var energyHint: String {
        switch energy { case 1: return "Exhausted"; case 2: return "Tired"; case 3: return "Average"; case 4: return "Energised"; default: return "Buzzing" }
    }
    private var sorenessHint: String {
        switch soreness { case 1: return "Can barely move"; case 2: return "Pretty sore"; case 3: return "Mild ache"; case 4: return "Barely noticeable"; default: return "Completely fresh" }
    }

    // MARK: - HealthKit pre-fill

    #if os(iOS)
    private var healthKitNote: String? {
        guard source == "healthkit" else { return nil }
        let hk = HealthKitService.shared
        if let h = hk.sleepHours {
            return String(format: "Sleep pre-filled from Apple Health (%.1f hrs)", h)
        }
        return nil
    }

    private func loadHealthKit() async {
        let hk = HealthKitService.shared
        if !hk.authorized { await hk.requestAuthorization() }
        if let rating = hk.sleepRating() {
            sleep = rating
            source = "healthkit"
        }
    }
    #else
    private func loadHealthKit() async {}
    #endif
}
