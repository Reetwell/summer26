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
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    private var macLayout: some View {
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

    // MARK: - iOS: Stitch editorial layout (glass meal cards, logged/unlogged)

    #if os(iOS)
    private struct MStrip: Identifiable {
        let id = UUID(); let label: String; let num: Int; let isToday: Bool
    }
    private var weekStrip: [MStrip] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let fmt = DateFormatter(); fmt.dateFormat = "EEE"
        return (0..<7).compactMap { off in
            guard let d = cal.date(byAdding: .day, value: off, to: start) else { return nil }
            let t = cal.isDateInToday(d)
            return MStrip(label: t ? "Today" : fmt.string(from: d), num: cal.component(.day, from: d), isToday: t)
        }
    }

    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // BUILD header
                HStack {
                    Text("BUILD").font(.serifDisplay(28)).foregroundStyle(Color.green700).kerning(1)
                    Spacer()
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "bell").font(.system(size: 17, weight: .medium)).foregroundStyle(.secondary)
                        Image(systemName: "gearshape").font(.system(size: 17, weight: .medium)).foregroundStyle(.secondary)
                        Text("RR").font(.sans(12, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    }
                }
                .padding(.top, Spacing.sm)
                .slideIn()

                // Date strip
                HStack(spacing: 0) {
                    ForEach(weekStrip) { d in
                        VStack(spacing: 1) {
                            HStack(spacing: 3) {
                                if d.isToday { Circle().fill(Color.green500).frame(width: 5, height: 5) }
                                Text(d.label.uppercased()).font(.sans(10, weight: .bold)).kerning(1)
                            }
                            .foregroundStyle(d.isToday ? Color.green500 : Color.secondary.opacity(0.6))
                            Text("\(d.num)").font(.serifDisplay(26))
                                .foregroundStyle(d.isToday ? Color.green700 : Color.secondary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, Spacing.md)
                .slideIn(delay: 0.04)

                // Big headline
                (Text("\(max(kcalTarget - eatenKcal, 0)) kcal").foregroundStyle(Color.green700)
                 + Text("\nleft today").foregroundStyle(.primary))
                    .font(.serifDisplay(52))
                    .lineSpacing(-4)
                    .padding(.top, Spacing.lg)
                    .contentTransition(.numericText())
                    .slideIn(delay: 0.08)

                // Macro strip
                HStack(spacing: Spacing.lg) {
                    macroStat("PROTEIN", eatenProtein, proteinTarget)
                    macroStat("CARBS", eatenCarbs, carbsTarget)
                    macroStat("FAT", eatenFat, fatTarget)
                }
                .padding(.vertical, Spacing.md)
                .slideIn(delay: 0.12)

                // Meal cards
                VStack(spacing: Spacing.md) {
                    ForEach(Array(meals.enumerated()), id: \.element.id) { i, meal in
                        mealCardIOS($meals[i])
                            .slideIn(delay: 0.16 + Double(i) * 0.06)
                    }
                }
                .padding(.top, Spacing.xs)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: eatenKcal)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private func macroStat(_ key: String, _ eaten: Int, _ target: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key).font(.sans(10, weight: .bold)).foregroundStyle(.secondary).kerning(1)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(eaten)").font(.sans(18, weight: .bold)).contentTransition(.numericText())
                Text("/\(target)g").font(.sans(12)).foregroundStyle(.secondary)
            }
        }
    }

    private func mealCardIOS(_ meal: Binding<Meal>) -> some View {
        let m = meal.wrappedValue
        return Group {
            if m.eaten {
                // Logged — filled card with icon panel
                HStack(spacing: 0) {
                    ZStack {
                        m.tint.opacity(0.16)
                        Image(systemName: m.icon).font(.system(size: 30)).foregroundStyle(m.tint)
                    }
                    .frame(width: 108)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(m.slot).font(.serifDisplay(24))
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) { meal.wrappedValue.eaten = false }
                            } label: {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundStyle(Color.green500)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(m.name).font(.sans(13)).foregroundStyle(.secondary).lineLimit(1)
                        Spacer(minLength: 4)
                        (Text("\(m.kcal)").font(.sans(30, weight: .bold))
                         + Text(" kcal").font(.sans(12)).foregroundStyle(.secondary))
                    }
                    .padding(Spacing.md)
                }
                .frame(height: 132)
                .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            } else {
                // Unlogged — dashed placeholder
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(m.slot).font(.serifDisplay(24)).foregroundStyle(.primary.opacity(0.55))
                        Text(m.slot == "Dinner" ? "Target: ~\(m.kcal) kcal to hit your goal" : "Recommended ~\(m.kcal) kcal")
                            .font(.sans(13)).foregroundStyle(.secondary)
                    }
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { meal.wrappedValue.eaten = true }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                            Text("Log \(m.slot)").font(.sans(14, weight: .bold))
                        }
                        .foregroundStyle(m.slot == "Dinner" ? .white : Color.green700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            m.slot == "Dinner"
                                ? AnyShapeStyle(LinearGradient(colors: [.green500, .green700], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.green500.opacity(0.1)),
                            in: RoundedRectangle(cornerRadius: 13)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(Spacing.md + 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )
            }
        }
    }
    #endif
}
