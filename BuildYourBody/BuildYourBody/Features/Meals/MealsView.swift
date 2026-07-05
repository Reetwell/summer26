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
    let tint: Color
    var eaten: Bool = false
}

struct MealsView: View {
    @State private var selectedDay = 3 // Thursday
    @State private var expandedMeal: UUID?

    @State private var meals = [
        Meal(slot: "Breakfast", name: "Greek yogurt bowl", kcal: 420, protein: 32, carbs: 48, fat: 12, icon: "sunrise.fill", tint: Color(hex: "#E8A13A"), eaten: true),
        Meal(slot: "Lunch", name: "Chicken burrito bowl", kcal: 640, protein: 45, carbs: 70, fat: 18, icon: "sun.max.fill", tint: Color(hex: "#4A90D9"), eaten: true),
        Meal(slot: "Snack", name: "Protein shake + banana", kcal: 310, protein: 28, carbs: 38, fat: 5, icon: "bolt.fill", tint: Color(hex: "#8E6FD8")),
        Meal(slot: "Dinner", name: "Salmon, rice & greens", kcal: 720, protein: 42, carbs: 68, fat: 26, icon: "moon.stars.fill", tint: .green500)
    ]

    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    private let dayNumbers = [1, 2, 3, 4, 5, 6, 7]

    private let kcalTarget = 2600
    private let proteinTarget = 160
    private let carbsTarget = 300
    private let fatTarget = 80

    private var eatenKcal: Int    { meals.filter(\.eaten).reduce(0) { $0 + $1.kcal } }
    private var eatenProtein: Int { meals.filter(\.eaten).reduce(0) { $0 + $1.protein } }
    private var eatenCarbs: Int   { meals.filter(\.eaten).reduce(0) { $0 + $1.carbs } }
    private var eatenFat: Int     { meals.filter(\.eaten).reduce(0) { $0 + $1.fat } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text("Meals")
                        .font(.serifDisplay(34))
                    Spacer()
                    Text("\(meals.filter(\.eaten).count)/\(meals.count) LOGGED")
                        .font(.sans(11, weight: .bold))
                        .foregroundStyle(Color.green500)
                        .kerning(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green500.opacity(0.12), in: Capsule())
                        .contentTransition(.numericText())
                }
                .slideIn()

                // Calendar strip
                HStack(spacing: Spacing.xs) {
                    ForEach(dayLetters.indices, id: \.self) { i in
                        dayPill(index: i)
                            .frame(maxWidth: .infinity)
                    }
                }
                .slideIn(delay: 0.05)

                // Remaining hero
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LEFT TODAY")
                                .font(.sans(10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                                .kerning(1.2)
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text("\(max(kcalTarget - eatenKcal, 0))")
                                    .font(.serifDisplay(40))
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())
                                Text("kcal")
                                    .font(.sans(14))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("eaten")
                                .font(.sans(11))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(eatenKcal)")
                                .font(.serifDisplay(20))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                    }

                    // Eaten progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.2))
                            Capsule().fill(.white)
                                .frame(width: geo.size.width * min(CGFloat(eatenKcal) / CGFloat(kcalTarget), 1))
                        }
                    }
                    .frame(height: 6)

                    // Macro mini-rows
                    HStack(spacing: Spacing.md) {
                        heroMacro("Protein", eaten: eatenProtein, target: proteinTarget)
                        heroMacro("Carbs", eaten: eatenCarbs, target: carbsTarget)
                        heroMacro("Fat", eaten: eatenFat, target: fatTarget)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.green500, .green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: eatenKcal)
                .slideIn(delay: 0.1)

                Text("TODAY'S MEALS")
                    .font(.sans(11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .padding(.top, 4)
                    .slideIn(delay: 0.14)

                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    mealCard($meals[index])
                        .slideIn(delay: 0.16 + Double(index) * 0.06)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    // MARK: components

    private func dayPill(index: Int) -> some View {
        let selected = selectedDay == index
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedDay = index
            }
        } label: {
            VStack(spacing: 3) {
                Text(dayLetters[index])
                    .font(.sans(11, weight: .semibold))
                    .foregroundStyle(selected ? .white.opacity(0.8) : .secondary)
                Text("\(dayNumbers[index])")
                    .font(.sans(15, weight: .bold))
                    .foregroundStyle(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selected ? Color.green500 : Color.bbSurface,
                in: RoundedRectangle(cornerRadius: Radius.md)
            )
            .shadow(color: selected ? Color.green500.opacity(0.35) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func heroMacro(_ label: String, eaten: Int, target: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.sans(11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(eaten)/\(target)g")
                    .font(.sans(10))
                    .foregroundStyle(.white.opacity(0.65))
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule().fill(.white.opacity(0.9))
                        .frame(width: geo.size.width * min(CGFloat(eaten) / CGFloat(target), 1))
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func mealCard(_ meal: Binding<Meal>) -> some View {
        let m = meal.wrappedValue
        let isExpanded = expandedMeal == m.id

        return BBCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: m.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(m.tint)
                        .frame(width: 42, height: 42)
                        .background(m.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: Radius.md))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.slot.uppercased())
                            .font(.sans(10, weight: .semibold))
                            .foregroundStyle(m.tint)
                            .kerning(1)
                        Text(m.name)
                            .font(.sans(15, weight: .semibold))
                            .foregroundStyle(m.eaten ? .secondary : .primary)
                        Text("\(m.kcal) kcal · \(m.protein)g protein")
                            .font(.sans(12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Log button — tick when eaten
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) {
                            meal.wrappedValue.eaten.toggle()
                        }
                    } label: {
                        Image(systemName: m.eaten ? "checkmark" : "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(m.eaten ? .white : Color.green500)
                            .frame(width: 32, height: 32)
                            .background(
                                m.eaten ? Color.green500 : Color.green500.opacity(0.12),
                                in: Circle()
                            )
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                if isExpanded {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            macroChip(label: "Protein", value: "\(m.protein)g", color: .green500)
                            macroChip(label: "Carbs", value: "\(m.carbs)g", color: Color(hex: "#4A90D9"))
                            macroChip(label: "Fat", value: "\(m.fat)g", color: Color(hex: "#E8A13A"))
                        }

                        HStack(spacing: Spacing.sm) {
                            actionButton("arrow.2.squarepath", "Swap meal")
                            actionButton("book.fill", "Recipe")
                        }
                    }
                    .padding(.top, Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .opacity(m.eaten && !isExpanded ? 0.75 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expandedMeal = isExpanded ? nil : m.id
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

    private func actionButton(_ icon: String, _ title: String) -> some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.sans(13, weight: .semibold))
            }
            .foregroundStyle(Color.green500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.green500.opacity(0.09), in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
