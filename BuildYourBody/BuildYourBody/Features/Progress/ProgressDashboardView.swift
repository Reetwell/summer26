import SwiftUI

struct ProgressDashboardView: View {
    private let ts = TrainingStore.shared
    @State private var selectedTimeline = 0

    private let timeline = ["This Month", "Last Month", "This Year", "All Time"]

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - macOS

    #if os(macOS)
    private var macLayout: some View {
        HStack(spacing: 0) {
            timelineRail
            ScrollView {
                VStack(spacing: 20) {
                    weightHero
                    strengthEmpty
                    HStack(alignment: .top, spacing: 20) {
                        weightTrendCard.frame(maxWidth: .infinity)
                        VStack(spacing: 20) {
                            consistencyCard
                            prCard
                        }
                        .frame(width: 320)
                    }
                    photosRow
                }
                .padding(40)
                .padding(.bottom, 96)
                .frame(maxWidth: 1080, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private var timelineRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TIMELINE")
                .font(.sans(11, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(1.4)
                .padding(.bottom, Spacing.lg)

            ForEach(timeline.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTimeline = i }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .stroke(selectedTimeline == i ? Color.green500 : Color.secondary.opacity(0.35), lineWidth: 2)
                                .background(Circle().fill(selectedTimeline == i ? Color.green500 : .clear))
                                .frame(width: 13, height: 13)
                            if i < timeline.count - 1 {
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1.5, height: 42)
                            }
                        }
                        Text(timeline[i])
                            .font(.sans(14, weight: .bold))
                            .foregroundStyle(selectedTimeline == i ? Color.green700 : .primary)
                            .padding(.top, -2)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 44)
        .padding(.horizontal, Spacing.lg)
        .frame(width: 210, alignment: .leading)
    }
    #endif

    // MARK: - iOS

    #if os(iOS)
    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Progress")
                    .font(.serifDisplay(34))
                    .slideIn()
                weightHero.slideIn(delay: 0.05)
                sectionLabel("STRENGTH").slideIn(delay: 0.1)
                strengthEmpty.slideIn(delay: 0.12)
                weightTrendCard.slideIn(delay: 0.16)
                consistencyCard.slideIn(delay: 0.2)
                prCard.slideIn(delay: 0.24)
                sectionLabel("PROGRESS PHOTOS").slideIn(delay: 0.28)
                photosRow.slideIn(delay: 0.3)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth()
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.sans(11, weight: .semibold)).foregroundStyle(.secondary).kerning(1.2).padding(.top, 4)
    }
    #endif

    // MARK: - shared cards

    private var weightHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WEIGHT TREND")
                .font(.sans(11, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .kerning(1.4)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("—").font(.serifDisplay(64)).foregroundStyle(.white)
                Text("kg").font(.serifDisplay(34)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(.top, 6)
            Text("No weigh-ins yet — log your weight to see your trend.")
                .font(.sans(14))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.green700, Color.green900],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }

    private var strengthEmpty: some View {
        BBCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.green500)
                    .frame(width: 44, height: 44)
                    .background(Color.green500.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.md))
                VStack(alignment: .leading, spacing: 2) {
                    Text("No lifts logged yet")
                        .font(.sans(15, weight: .semibold))
                    Text("Start a session and your top lifts and PRs will show here.")
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var weightTrendCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Body Weight").font(.sans(17, weight: .semibold))
                        Text("Last 30 days").font(.sans(12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("—").font(.serifDisplay(26)).foregroundStyle(.secondary)
                        Text("CURRENT").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(1)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.green500.opacity(0.05))
                    VStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.green500.opacity(0.5))
                        Text("Your weight trend will appear here")
                            .font(.sans(12))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 190)
            }
        }
    }

    private var consistencyCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green700)
                        .frame(width: 32, height: 32)
                        .background(Color.green500.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                    Text("Consistency").font(.sans(17, weight: .semibold))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(ts.totalWorkouts)").font(.serifDisplay(32))
                        Text("TOTAL WORKOUTS").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(ts.currentStreak)").font(.serifDisplay(32)).foregroundStyle(Color.green700)
                        Text("DAY STREAK").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                    }
                    Spacer()
                }
                Text("THIS WEEK").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        let done = i < ts.sessionsThisWeek
                        RoundedRectangle(cornerRadius: 8)
                            .fill(done ? Color.green700 : Color.green500.opacity(0.12))
                            .frame(height: 34)
                    }
                }
            }
        }
    }

    private var prCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").font(.system(size: 14)).foregroundStyle(Color(hex: "#E8A13A"))
                    Text("Personal Records").font(.sans(16, weight: .semibold))
                }
                Text("No records yet — they'll show up as you hit new bests.")
                    .font(.sans(13)).foregroundStyle(.secondary)
            }
        }
    }

    private var photosRow: some View {
        HStack(spacing: 16) {
            // Add photo tile
            VStack(spacing: 8) {
                Image(systemName: "camera").font(.system(size: 22)).foregroundStyle(.secondary)
                Text("Add Photo").font(.sans(12)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
            photoPlaceholder
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Image(systemName: "figure.stand").font(.system(size: 40)).foregroundStyle(.secondary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
