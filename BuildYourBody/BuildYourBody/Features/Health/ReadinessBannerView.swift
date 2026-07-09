import SwiftUI

// Compact inline banner used on Today + Training tabs.
// Shows score ring + label if checked-in today; "How are you feeling?" prompt otherwise.
struct ReadinessBannerView: View {
    @State private var showCheckIn = false
    private let store = ReadinessStore.shared

    var body: some View {
        Group {
            if let entry = store.todayEntry {
                scoreBanner(entry)
            } else {
                promptBanner
            }
        }
        .sheet(isPresented: $showCheckIn) {
            ReadinessCheckInView()
        }
    }

    // MARK: - Score banner (checked-in)

    private func scoreBanner(_ entry: ReadinessEntry) -> some View {
        BBCard {
            HStack(spacing: Spacing.md) {
                scoreRing(score: entry.score)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Readiness")
                            .font(.sans(15, weight: .semibold))
                        sourceBadge(entry.source)
                    }
                    Text(store.scoreHint)
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showCheckIn = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func scoreRing(score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(ringColor(score).opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(ringColor(score), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.serifDisplay(20))
        }
        .frame(width: 54, height: 54)
    }

    private func ringColor(_ score: Int) -> Color {
        switch score {
        case 80...: return Color.green500
        case 60..<80: return Color(hex: "#E8A13A")
        default: return Color(hex: "#E05C5C")
        }
    }

    private func sourceBadge(_ source: String) -> some View {
        Group {
            if source == "healthkit" {
                Label("Health", systemImage: "heart.fill")
                    .font(.sans(10, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E05C5C"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#E05C5C").opacity(0.1), in: Capsule())
            }
        }
    }

    // MARK: - Prompt banner (not yet checked in)

    private var promptBanner: some View {
        Button {
            showCheckIn = true
        } label: {
            BBCard {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                        Image(systemName: "questionmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Readiness")
                            .font(.sans(15, weight: .semibold))
                        Text("How are you feeling today? Tap to check in.")
                            .font(.sans(13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - macOS hero variant (used inside the left readiness pane on Today + Training)

struct ReadinessHeroContent: View {
    private let store = ReadinessStore.shared
    @State private var showCheckIn = false

    var scoreValue: CGFloat {
        CGFloat(store.todayScore ?? 0) / 100
    }

    var body: some View {
        Group {
            if let entry = store.todayEntry {
                heroFilled(entry)
            } else {
                heroEmpty
            }
        }
        .sheet(isPresented: $showCheckIn) {
            ReadinessCheckInView()
        }
    }

    private func heroFilled(_ entry: ReadinessEntry) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                Text("\(entry.score)").font(.serifDisplay(110)).foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("READINESS").font(.sans(12, weight: .bold)).kerning(2).foregroundStyle(Color(hex: "#86f8c9"))
                    Text(store.scoreLabel.uppercased()).font(.serifDisplay(26)).foregroundStyle(.white)
                }
            }
            HStack(spacing: 8) {
                heroPill(sleepPillText(entry))
                heroPill(store.scoreHint)
                if entry.source == "healthkit" {
                    heroPill("Apple Health")
                }
            }
            .padding(.top, Spacing.sm)

            Spacer()

            Button {
                showCheckIn = true
            } label: {
                Label("Update check-in", systemImage: "pencil")
                    .font(.sans(13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private var heroEmpty: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("No readiness data yet")
                .font(.serifDisplay(36))
                .foregroundStyle(.white)
            Text("Check in to tune today's session")
                .font(.sans(14))
                .foregroundStyle(.white.opacity(0.7))
            Button {
                showCheckIn = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Check in now")
                }
                .font(.sans(14, weight: .semibold))
                .foregroundStyle(Color.green900)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white, in: Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func heroPill(_ text: String) -> some View {
        Text(text)
            .font(.sans(13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(.white.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
    }

    private func sleepPillText(_ entry: ReadinessEntry) -> String {
        "Sleep: \(["", "Poor", "Low", "OK", "Good", "Great"][entry.sleep])"
    }
}
