import SwiftUI

// Progress is EFFORT-first by design: sessions, streaks, consistency and effort
// milestones — never body weight, size or strength (body-neutral, AADC-safe for the
// 14–21 audience, mirrors the rank/effort guardrail).
struct ProgressDashboardView: View {
    private let ts = TrainingStore.shared

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - Layouts

    #if os(macOS)
    private var macLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Progress").font(.bbLargeTitle)
                effortHero
                HStack(alignment: .top, spacing: 20) {
                    consistencyCard.frame(maxWidth: .infinity)
                    milestonesCard.frame(width: 360)
                }
            }
            .padding(40)
            .padding(.bottom, 96)
            .frame(maxWidth: 1080, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }
    #endif

    #if os(iOS)
    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Progress").font(.bbLargeTitle).slideIn()
                effortHero.slideIn(delay: 0.05)
                consistencyCard.slideIn(delay: 0.1)
                milestonesCard.slideIn(delay: 0.16)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth()
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }
    #endif

    // MARK: - Effort hero

    private var effortHero: some View {
        let streak = ts.currentStreak
        let total = ts.totalWorkouts
        return VStack(alignment: .leading, spacing: 16) {
            Text("YOUR EFFORT")
                .font(.bbEyebrow)
                .foregroundStyle(.white.opacity(0.7))
                .kerning(1.4)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                heroStat(value: streak, label: "DAY STREAK")
                Rectangle().fill(.white.opacity(0.22))
                    .frame(width: 1, height: 52)
                    .padding(.horizontal, 24)
                heroStat(value: total, label: "SESSIONS")
                Spacer(minLength: 0)
            }

            Text(streak > 0
                 ? "You're on a roll — keep it going."
                 : "Every session counts. Log one to start your streak.")
                .font(.bbCallout)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.green500, Color.green900],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }

    private func heroStat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.serifDisplay(56)).foregroundStyle(.white)
            Text(label)
                .font(.sans(10, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .kerning(0.9)
        }
    }

    // MARK: - Consistency (real 7-day data)

    private var consistencyCard: some View {
        let week = ts.last7DaysProgress()
        let planned = ts.sessionsPlannedThisWeek
        return BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cardHeader("calendar", "This week")

                HStack(spacing: 8) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        let isToday = Calendar.current.isDateInToday(day.date)
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(day.done ? Color.bbAccent : Color.bbTint)
                                if day.done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color.bbAccent, lineWidth: isToday && !day.done ? 1.5 : 0)
                            )
                            Text(dayLetter(day.date))
                                .font(.sans(10, weight: .bold))
                                .foregroundStyle(isToday ? Color.green700 : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                let doneThisWeek = week.filter(\.done).count
                Text(planned > 0
                     ? "\(doneThisWeek) of \(planned) planned sessions done"
                     : "\(doneThisWeek) sessions this week")
                    .font(.bbCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Milestones (effort-based, replaces strength PRs)

    private struct Milestone: Identifiable {
        enum Metric { case sessions, streak }
        let id = UUID()
        let title: String
        let target: Int
        let metric: Metric
    }

    private let milestones: [Milestone] = [
        .init(title: "First session",  target: 1,  metric: .sessions),
        .init(title: "3-day streak",   target: 3,  metric: .streak),
        .init(title: "10 sessions",    target: 10, metric: .sessions),
        .init(title: "7-day streak",   target: 7,  metric: .streak),
        .init(title: "25 sessions",    target: 25, metric: .sessions),
        .init(title: "50 sessions",    target: 50, metric: .sessions),
    ]

    private func value(for m: Milestone) -> Int {
        switch m.metric {
        case .sessions: ts.totalWorkouts
        case .streak:   ts.currentStreak
        }
    }

    private var milestonesCard: some View {
        let next = milestones.first { value(for: $0) < $0.target }
        return BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cardHeader("flag.checkered", "Milestones")

                if let next {
                    let v = value(for: next)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Next: \(next.title)").font(.bbHeadline)
                            Spacer()
                            Text("\(v)/\(next.target)")
                                .font(.sans(13, weight: .semibold))
                                .foregroundStyle(Color.green700)
                        }
                        ProgressView(value: Double(v), total: Double(next.target))
                            .tint(Color.bbAccent)
                    }
                } else {
                    Text("Every milestone cleared — legend. 🌟").font(.bbHeadline)
                }

                let cols = [GridItem(.adaptive(minimum: 104), spacing: 8)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                    ForEach(milestones) { m in
                        let achieved = value(for: m) >= m.target
                        HStack(spacing: 6) {
                            Image(systemName: achieved ? "checkmark.seal.fill" : "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(achieved ? Color.bbAccent : .secondary.opacity(0.5))
                            Text(m.title)
                                .font(.bbCaption)
                                .foregroundStyle(achieved ? .primary : .secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(achieved ? Color.bbTint : Color.secondary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func cardHeader(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.green700)
                .frame(width: 32, height: 32)
                .background(Color.bbTint, in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(.bbHeadline)
        }
    }

    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // single-letter weekday
        return f.string(from: date)
    }
}
