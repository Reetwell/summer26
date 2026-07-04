import SwiftUI

struct Routine: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [String]
    let duration: String
}

struct WeekDayState: Identifiable {
    let id = UUID()
    let letter: String
    let state: DayState

    enum DayState { case done, today, upcoming, rest }
}

struct TrainingView: View {
    private let week: [WeekDayState] = [
        .init(letter: "M", state: .done),
        .init(letter: "T", state: .done),
        .init(letter: "W", state: .rest),
        .init(letter: "T", state: .today),
        .init(letter: "F", state: .upcoming),
        .init(letter: "S", state: .upcoming),
        .init(letter: "S", state: .rest)
    ]

    private let routines = [
        Routine(name: "Push Day A", exercises: ["Bench Press", "Incline DB Press", "Overhead Press", "Lateral Raise", "Triceps Pushdown", "Cable Fly"], duration: "~55 min"),
        Routine(name: "Pull Day A", exercises: ["Deadlift", "Pull-Ups", "Barbell Row", "Face Pull", "Barbell Curl", "Hammer Curl"], duration: "~50 min"),
        Routine(name: "Legs Day", exercises: ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Walking Lunge", "Calf Raise", "Leg Extension"], duration: "~60 min"),
        Routine(name: "Upper B", exercises: ["Incline Bench Press", "Lat Pulldown", "DB Shoulder Press", "Seated Cable Row", "Preacher Curl", "Skull Crushers"], duration: "~55 min")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text("Training")
                        .font(.serifDisplay(34))
                    Spacer()
                    Text("PHASE 2 · WK 3")
                        .font(.sans(11, weight: .bold))
                        .foregroundStyle(Color.green500)
                        .kerning(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green500.opacity(0.12), in: Capsule())
                }
                .slideIn()

                // TODAY hero — the one thing to do right now
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("TODAY · THURSDAY")
                            .font(.sans(10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.75))
                            .kerning(1.2)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                            Text("6")
                                .font(.sans(12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Push Day A")
                            .font(.serifDisplay(30))
                            .foregroundStyle(.white)
                        Text("6 exercises · ~55 min · last time 12,400 kg")
                            .font(.sans(13))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Start button — white on green, impossible to miss
                    Button {} label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start workout")
                                .font(.sans(16, weight: .bold))
                        }
                        .foregroundStyle(Color.green700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white, in: RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(Spacing.md)
                .background(
                    LinearGradient(colors: [.green500, .green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )
                .slideIn(delay: 0.06)

                // Week strip
                BBCard(padding: Spacing.sm) {
                    HStack {
                        ForEach(week) { day in
                            weekDot(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .slideIn(delay: 0.12)

                // Quick stats
                HStack(spacing: Spacing.sm) {
                    statCard(value: "24.8k", unit: "kg", label: "volume this week")
                    statCard(value: "2", unit: "PRs", label: "new records")
                    statCard(value: "3/5", unit: "", label: "sessions done")
                }
                .slideIn(delay: 0.18)

                // Routines
                HStack {
                    Text("YOUR ROUTINES")
                        .font(.sans(11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(1.2)
                    Spacer()
                    Button {} label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("New")
                                .font(.sans(13, weight: .semibold))
                        }
                        .foregroundStyle(Color.green500)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                .slideIn(delay: 0.22)

                ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                    routineCard(routine)
                        .slideIn(delay: 0.24 + Double(index) * 0.05)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    // MARK: components

    private func weekDot(_ day: WeekDayState) -> some View {
        VStack(spacing: 6) {
            Text(day.letter)
                .font(.sans(11, weight: .semibold))
                .foregroundStyle(day.state == .today ? Color.green500 : .secondary)

            ZStack {
                switch day.state {
                case .done:
                    Circle().fill(Color.green500)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                case .today:
                    Circle().stroke(Color.green500, lineWidth: 2)
                    Circle().fill(Color.green500.opacity(0.15)).padding(4)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.green500)
                case .upcoming:
                    Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                case .rest:
                    Circle().fill(Color.secondary.opacity(0.07))
                    Image(systemName: "zzz")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 32, height: 32)
        }
    }

    private func statCard(value: String, unit: String, label: String) -> some View {
        BBCard(padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.serifDisplay(20))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.sans(11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(label)
                    .font(.sans(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func routineCard(_ routine: Routine) -> some View {
        Button {} label: {
            BBCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text(routine.name)
                            .font(.sans(16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(routine.exercises.count) exercises · \(routine.duration)")
                            .font(.sans(12))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }

                    // Exercise preview — first 3 + count
                    Text(previewLine(routine))
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func previewLine(_ routine: Routine) -> String {
        let first = routine.exercises.prefix(3).joined(separator: " · ")
        let rest = routine.exercises.count - 3
        return rest > 0 ? "\(first)  +\(rest) more" : first
    }
}
