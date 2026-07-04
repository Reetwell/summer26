import SwiftUI

struct TodayView: View {
    private var dateString: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
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

                // Nutrition card — ring + macro bars
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

                // Readiness
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

                // Today's training
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

                // Quick stats row
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
        .toolbar(.hidden, for: .navigationBar)
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
}
