import SwiftUI

struct WorkoutDay: Identifiable {
    let id = UUID()
    let day: String
    let name: String
    let detail: String
    let icon: String
    let done: Bool
    let isToday: Bool
    let isRest: Bool
}

struct TrainingView: View {
    private let week = [
        WorkoutDay(day: "Mon", name: "Push Day A", detail: "6 exercises · done", icon: "dumbbell.fill", done: true, isToday: false, isRest: false),
        WorkoutDay(day: "Tue", name: "Pull Day A", detail: "6 exercises · done", icon: "dumbbell.fill", done: true, isToday: false, isRest: false),
        WorkoutDay(day: "Wed", name: "Rest", detail: "Recovery day", icon: "moon.zzz.fill", done: true, isToday: false, isRest: true),
        WorkoutDay(day: "Thu", name: "Push Day A", detail: "6 exercises · ~55 min", icon: "dumbbell.fill", done: false, isToday: true, isRest: false),
        WorkoutDay(day: "Fri", name: "Legs Day", detail: "7 exercises · ~60 min", icon: "figure.strengthtraining.traditional", done: false, isToday: false, isRest: false),
        WorkoutDay(day: "Sat", name: "Pull Day B", detail: "6 exercises · ~50 min", icon: "dumbbell.fill", done: false, isToday: false, isRest: false),
        WorkoutDay(day: "Sun", name: "Rest", detail: "Recovery day", icon: "moon.zzz.fill", done: false, isToday: false, isRest: true)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Training")
                    .font(.serifDisplay(34))
                    .slideIn()

                // Phase hero — green gradient like the web account hero
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("PHASE 2 · HYPERTROPHY")
                        .font(.sans(10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .kerning(1.2)
                    Text("Week 3 of 6")
                        .font(.serifDisplay(26))
                        .foregroundStyle(.white)

                    // Week progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.2))
                            Capsule().fill(.white)
                                .frame(width: geo.size.width * 0.43)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)

                    Text("3 of 7 sessions done this week")
                        .font(.sans(12))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.green500, .green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )
                .slideIn(delay: 0.06)

                Text("THIS WEEK")
                    .font(.sans(11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .padding(.top, 4)
                    .slideIn(delay: 0.1)

                ForEach(Array(week.enumerated()), id: \.element.id) { index, day in
                    dayCard(day)
                        .slideIn(delay: 0.12 + Double(index) * 0.05)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func dayCard(_ day: WorkoutDay) -> some View {
        BBCard(padding: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                Text(day.day)
                    .font(.sans(12, weight: .semibold))
                    .foregroundStyle(day.isToday ? Color.green500 : .secondary)
                    .frame(width: 36)

                Image(systemName: day.done ? "checkmark" : day.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(day.done ? .white : (day.isRest ? Color.secondary : Color.green500))
                    .frame(width: 38, height: 38)
                    .background(
                        day.done ? Color.green500 : (day.isRest ? Color.secondary.opacity(0.1) : Color.green500.opacity(0.12)),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(day.name)
                        .font(.sans(15, weight: day.isToday ? .semibold : .medium))
                        .foregroundStyle(day.isRest && !day.isToday ? .secondary : .primary)
                    Text(day.detail)
                        .font(.sans(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if day.isToday {
                    Text("TODAY")
                        .font(.sans(10, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green500, in: Capsule())
                } else if !day.isRest {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(day.isToday ? Color.green500.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }
}
