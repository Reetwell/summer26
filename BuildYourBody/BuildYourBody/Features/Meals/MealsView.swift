import SwiftUI

struct Meal: Identifiable {
    let id = UUID()
    let slot: String
    let name: String
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let icon: String
}

struct MealsView: View {
    @State private var selectedDay = 3 // Thursday
    @State private var expandedMeal: UUID?

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private let meals = [
        Meal(slot: "Breakfast", name: "Greek yogurt bowl", kcal: 420, protein: 32, carbs: 48, fat: 12, icon: "sunrise.fill"),
        Meal(slot: "Lunch", name: "Chicken burrito bowl", kcal: 640, protein: 45, carbs: 70, fat: 18, icon: "sun.max.fill"),
        Meal(slot: "Snack", name: "Protein shake + banana", kcal: 310, protein: 28, carbs: 38, fat: 5, icon: "bolt.fill"),
        Meal(slot: "Dinner", name: "Salmon, rice & greens", kcal: 720, protein: 42, carbs: 68, fat: 26, icon: "moon.stars.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Meals")
                    .font(.serifDisplay(34))
                    .slideIn()

                // Day selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days.indices, id: \.self) { i in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedDay = i
                                }
                            } label: {
                                Text(days[i])
                                    .font(.sans(14, weight: selectedDay == i ? .semibold : .regular))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedDay == i ? Color.green500 : Color.bbSurface,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedDay == i ? .white : .primary)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .slideIn(delay: 0.05)

                // Day summary
                BBCard(padding: Spacing.sm) {
                    HStack {
                        daySummaryStat(value: "2,090", label: "kcal")
                        Divider().frame(height: 28)
                        daySummaryStat(value: "147g", label: "protein")
                        Divider().frame(height: 28)
                        daySummaryStat(value: "224g", label: "carbs")
                        Divider().frame(height: 28)
                        daySummaryStat(value: "61g", label: "fat")
                    }
                }
                .slideIn(delay: 0.1)

                // Meal cards
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    mealCard(meal)
                        .slideIn(delay: 0.15 + Double(index) * 0.06)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func daySummaryStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.sans(15, weight: .semibold))
            Text(label)
                .font(.sans(11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func mealCard(_ meal: Meal) -> some View {
        let isExpanded = expandedMeal == meal.id

        return BBCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: meal.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.green500)
                        .frame(width: 40, height: 40)
                        .background(Color.green500.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.slot.uppercased())
                            .font(.sans(10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .kerning(1)
                        Text(meal.name)
                            .font(.sans(15, weight: .semibold))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meal.kcal)")
                            .font(.sans(15, weight: .semibold))
                        Text("kcal")
                            .font(.sans(11))
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded {
                    HStack(spacing: Spacing.sm) {
                        macroChip(label: "Protein", value: "\(meal.protein)g", color: .green500)
                        macroChip(label: "Carbs", value: "\(meal.carbs)g", color: Color(hex: "#4A90D9"))
                        macroChip(label: "Fat", value: "\(meal.fat)g", color: Color(hex: "#E8A13A"))
                    }
                    .padding(.top, Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expandedMeal = isExpanded ? nil : meal.id
            }
        }
    }

    private func macroChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.sans(14, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.sans(11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.sm))
    }
}
