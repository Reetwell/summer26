import SwiftUI

struct TodayView: View {
    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - iOS: Stitch-style editorial layout

    #if os(iOS)
    private struct StripDay: Identifiable {
        let id = UUID()
        let label: String
        let num: Int
        let isToday: Bool
    }

    // Current week, Monday first
    private var weekStrip: [StripDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = Date.now
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let isToday = cal.isDateInToday(day)
            return StripDay(
                label: isToday ? "TODAY" : fmt.string(from: day).uppercased(),
                num: cal.component(.day, from: day),
                isToday: isToday
            )
        }
    }

    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .slideIn()
                dateStrip
                    .padding(.top, Spacing.sm)
                    .slideIn(delay: 0.04)

                // Statement headline
                (Text("Push day,").foregroundStyle(Color.green700)
                 + Text("\nand you're ready.").foregroundStyle(.primary))
                    .font(.serifDisplay(42))
                    .lineSpacing(0)
                    .padding(.top, Spacing.lg)
                    .slideIn(delay: 0.08)

                // Stat strip
                HStack(spacing: Spacing.lg) {
                    stripStat("READINESS", "82", sub: "/100")
                    stripStat("KCAL LEFT", "760")
                    stripStat("STEPS", "8,412")
                    stripStat("STREAK", "6", sub: "days")
                }
                .padding(.vertical, Spacing.md)
                .slideIn(delay: 0.12)

                VStack(spacing: Spacing.md) {
                    trainingHero
                        .slideIn(delay: 0.16)
                    nutritionCard
                        .slideIn(delay: 0.2)
                    duoRow
                        .slideIn(delay: 0.24)
                    recentCard
                        .slideIn(delay: 0.28)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private var header: some View {
        HStack {
            Text("BUILD")
                .font(.serifDisplay(28))
                .foregroundStyle(Color.green700)
                .kerning(1)
            Spacer()
            HStack(spacing: Spacing.md) {
                Image(systemName: "bell")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("RR")
                    .font(.sans(12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        LinearGradient(colors: [.green500, .green900],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
            }
        }
        .padding(.top, Spacing.sm)
    }

    private var dateStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekStrip) { day in
                VStack(spacing: 1) {
                    HStack(spacing: 3) {
                        if day.isToday {
                            Circle().fill(Color.green500).frame(width: 5, height: 5)
                        }
                        Text(day.label)
                            .font(.sans(10, weight: .bold))
                            .kerning(1.1)
                    }
                    .foregroundStyle(day.isToday ? Color.green500 : Color.secondary.opacity(0.65))
                    Text("\(day.num)")
                        .font(.serifDisplay(26))
                        .foregroundStyle(day.isToday ? Color.green700 : Color.secondary.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func stripStat(_ key: String, _ value: String, sub: String = "") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.sans(10, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(1.1)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.sans(16, weight: .bold))
                if !sub.isEmpty {
                    Text(sub).font(.sans(11)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var trainingHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S TRAINING · PUSH DAY A")
                .font(.sans(10, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .kerning(1.3)
            Text("Chest, shoulders & triceps")
                .font(.serifDisplay(26))
                .foregroundStyle(.white)
                .padding(.top, 7)
            Text("6 exercises · ~55 min · last time 12,400 kg")
                .font(.sans(12.5))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 3)

            // Exercise chips
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    heroChip("Bench Press"); heroChip("Incline DB"); heroChip("Overhead Press")
                }
                HStack(spacing: 7) {
                    heroChip("Lateral Raise"); heroChip("+2 more")
                }
            }
            .padding(.vertical, Spacing.md)

            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 13))
                    Text("Start workout").font(.sans(15, weight: .bold))
                }
                .foregroundStyle(Color.green900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Spacing.md + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.green500, .green900],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private func heroChip(_ label: String) -> some View {
        Text(label)
            .font(.sans(11.5))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(.white.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
    }

    private var nutritionCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("NUTRITION")
                    .font(.sans(10.5, weight: .bold))
                    .foregroundStyle(.secondary)
                    .kerning(1.3)
                HStack(spacing: Spacing.lg) {
                    CalorieRingView(consumed: 1840, target: 2600, size: 110, lineWidth: 10)
                    VStack(spacing: Spacing.sm) {
                        MacroBarView(label: "Protein", value: 120, target: 180, color: .green500, delay: 0.3)
                        MacroBarView(label: "Carbs", value: 150, target: 250, color: Color(hex: "#4A90D9"), delay: 0.4)
                        MacroBarView(label: "Fat", value: 45, target: 65, color: Color(hex: "#E8A13A"), delay: 0.5)
                    }
                }
            }
        }
    }

    private var duoRow: some View {
        HStack(spacing: Spacing.md) {
            BBCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("READINESS")
                        .font(.sans(10.5, weight: .bold))
                        .foregroundStyle(.secondary)
                        .kerning(1.3)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().stroke(Color.green500.opacity(0.13), lineWidth: 6)
                            Circle().trim(from: 0, to: 0.82)
                                .stroke(Color.green500, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("82").font(.serifDisplay(15))
                        }
                        .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Recovered").font(.sans(14, weight: .bold))
                            Text("Good day to push").font(.sans(11.5)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            BBCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("WEIGHT")
                        .font(.sans(10.5, weight: .bold))
                        .foregroundStyle(.secondary)
                        .kerning(1.3)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("74.2").font(.serifDisplay(26))
                        Text("kg").font(.sans(13)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 3) {
                        Text("−0.4 kg").font(.sans(11.5, weight: .bold)).foregroundStyle(Color.green500)
                        Text("this week").font(.sans(11.5)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var recentCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("RECENT")
                    .font(.sans(10.5, weight: .bold))
                    .foregroundStyle(.secondary)
                    .kerning(1.3)
                    .padding(.bottom, 6)
                recentRow(icon: "dumbbell.fill", name: "Pull Day A", detail: "Yesterday · 52 min", value: "11,900 kg")
                Divider()
                recentRow(icon: "fork.knife", name: "Lunch logged", detail: "Grilled chicken salad", value: "620 kcal")
            }
        }
    }

    private func recentRow(icon: String, name: String, detail: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.green700)
                .frame(width: 36, height: 36)
                .background(Color.green500.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.sans(13.5, weight: .semibold))
                Text(detail).font(.sans(11.5)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(value).font(.sans(13.5, weight: .bold)).foregroundStyle(Color.green700)
        }
        .padding(.vertical, 10)
    }
    #endif

    // MARK: - macOS: previous card layout (own redesign coming later)

    #if os(macOS)
    private var dateString: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private var macLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString.uppercased())
                        .font(.sans(11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(1.2)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today")
                            .font(.serifDisplay(34))
                        Spacer()
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                            Text("6 day streak")
                                .font(.sans(13, weight: .semibold))
                        }
                        .foregroundStyle(Color.green500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.green500.opacity(0.12), in: Capsule())
                    }
                }
                .slideIn()

                BBCard {
                    VStack(spacing: Spacing.md) {
                        HStack {
                            Text("Nutrition")
                                .font(.sans(15, weight: .semibold))
                            Spacer()
                            Text("On track")
                                .font(.sans(12, weight: .semibold))
                                .foregroundStyle(Color.green500)
                        }

                        HStack(spacing: Spacing.lg) {
                            CalorieRingView(consumed: 1840, target: 2600)

                            VStack(spacing: Spacing.sm) {
                                MacroBarView(label: "Protein", value: 128, target: 160, color: .green500, delay: 0.35)
                                MacroBarView(label: "Carbs",   value: 210, target: 300, color: Color(hex: "#4A90D9"), delay: 0.45)
                                MacroBarView(label: "Fat",     value: 52,  target: 80,  color: Color(hex: "#E8A13A"), delay: 0.55)
                            }
                        }
                    }
                }
                .slideIn(delay: 0.06)

                BBCard {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .stroke(Color.green500.opacity(0.14), lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: 0.82)
                                .stroke(Color.green500, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("82")
                                .font(.serifDisplay(20))
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Readiness")
                                .font(.sans(15, weight: .semibold))
                            Text("Recovered — good day to push.")
                                .font(.sans(13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .slideIn(delay: 0.12)

                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Today's training")
                                .font(.sans(15, weight: .semibold))
                            Spacer()
                            Text("Push · Week 3")
                                .font(.sans(12))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: Spacing.md) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.green500)
                                .frame(width: 44, height: 44)
                                .background(Color.green500.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Push Day A")
                                    .font(.sans(16, weight: .semibold))
                                Text("6 exercises · ~55 min")
                                    .font(.sans(13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        BBButton(title: "Start workout") {}
                            .padding(.top, 4)
                    }
                }
                .slideIn(delay: 0.18)

                HStack(spacing: Spacing.sm) {
                    quickStat(icon: "figure.walk", value: "8,412", label: "steps")
                    quickStat(icon: "drop.fill", value: "1.8L", label: "water")
                    quickStat(icon: "scalemass.fill", value: "74.2kg", label: "weight")
                }
                .slideIn(delay: 0.24)
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private func quickStat(icon: String, value: String, label: String) -> some View {
        BBCard(padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.green500)
                Text(value)
                    .font(.serifDisplay(18))
                Text(label)
                    .font(.sans(11))
                    .foregroundStyle(.secondary)
            }
        }
    }
    #endif
}
