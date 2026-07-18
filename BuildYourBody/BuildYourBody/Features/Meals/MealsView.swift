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
    @State private var meals = [
        Meal(slot: "Breakfast", name: "Greek yogurt bowl", kcal: 420, protein: 32, carbs: 48, fat: 12, icon: "sunrise.fill", tint: Color(hex: "#E8A13A")),
        Meal(slot: "Lunch", name: "Chicken burrito bowl", kcal: 640, protein: 45, carbs: 70, fat: 18, icon: "sun.max.fill", tint: Color(hex: "#4A90D9")),
        Meal(slot: "Snack", name: "Protein shake + banana", kcal: 310, protein: 28, carbs: 38, fat: 5, icon: "bolt.fill", tint: Color(hex: "#8E6FD8")),
        Meal(slot: "Dinner", name: "Salmon, rice & greens", kcal: 720, protein: 42, carbs: 68, fat: 26, icon: "moon.stars.fill", tint: .green500)
    ]

    @State private var showShopping = false

    private let kcalTarget = 2600
    private let proteinTarget = 160
    private let carbsTarget = 300
    private let fatTarget = 80

    // Shopping CTA card — blends into the page, opens the shopping list
    private var shoppingCTA: some View {
        Button {
            showShopping = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(colors: [.green500, .green700], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shopping list")
                        .font(.sans(15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Everything for this week's meals")
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.green500)
            }
            .padding(Spacing.md)
            .background(Color.green500.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.green500.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Compact shopping pill for the macOS headline row
    private var shoppingPill: some View {
        Button {
            showShopping = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cart.fill").font(.system(size: 14))
                Text("Shopping list").font(.sans(14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.green500, .green700], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .shadow(color: Color.green700.opacity(0.3), radius: 8, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

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

    #if os(macOS)
    // MARK: - macOS: Stitch split-pane (date rail + headline + asymmetric grid)

    private struct MacDay: Identifiable {
        let id = UUID(); let label: String; let num: Int; let isToday: Bool
    }
    private var macWeek: [MacDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let fmt = DateFormatter(); fmt.dateFormat = "EEE"
        return (0..<7).compactMap { off in
            guard let d = cal.date(byAdding: .day, value: off, to: start) else { return nil }
            let t = cal.isDateInToday(d)
            return MacDay(label: fmt.string(from: d), num: cal.component(.day, from: d), isToday: t)
        }
    }

    private var macLayout: some View {
        HStack(spacing: 0) {
            macDateRail
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Big headline + shopping access
                    HStack(alignment: .top) {
                        (Text("\(max(kcalTarget - eatenKcal, 0)) kcal").foregroundStyle(Color.green700)
                         + Text("\nleft today").foregroundStyle(.primary))
                            .font(.serifDisplay(64))
                            .lineSpacing(-6)
                            .contentTransition(.numericText())
                        Spacer()
                        shoppingPill
                            .padding(.top, 8)
                    }

                    // Macro strip
                    HStack(spacing: Spacing.xl) {
                        macMacro("PROTEIN", eatenProtein, proteinTarget)
                        macMacro("CARBS", eatenCarbs, carbsTarget)
                        macMacro("FAT", eatenFat, fatTarget)
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)

                    // Asymmetric grid: wide/narrow, narrow/wide
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            mealCardMac($meals[0]).frame(maxWidth: .infinity)
                            mealCardMac($meals[1]).frame(width: 330)
                        }
                        HStack(alignment: .top, spacing: 20) {
                            mealCardMac($meals[2]).frame(width: 330)
                            mealCardMac($meals[3]).frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(56)
                .padding(.bottom, 96)
                .frame(maxWidth: 1000, alignment: .leading)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: eatenKcal)
            }
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
        .sheet(isPresented: $showShopping) { ShoppingSheet(isPresented: $showShopping) }
    }

    private var macDateRail: some View {
        VStack(spacing: 0) {
            ForEach(Array(macWeek.enumerated()), id: \.element.id) { i, day in
                VStack(spacing: 3) {
                    Text(day.label.uppercased())
                        .font(.sans(11, weight: .bold))
                        .kerning(1.4)
                        .foregroundStyle(day.isToday ? Color.green500 : Color.secondary.opacity(0.7))
                    Text("\(day.num)")
                        .font(.serifDisplay(day.isToday ? 44 : 38))
                        .foregroundStyle(day.isToday ? Color.green700 : Color.secondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    if day.isToday {
                        Capsule().fill(Color.green500).frame(width: 3, height: 44).offset(x: 6)
                    }
                }
                if i < macWeek.count - 1 { Spacer(minLength: 14) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
        .frame(width: 128)
        .background(Color.bbSurface)
    }

    private func macMacro(_ key: String, _ eaten: Int, _ target: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key).font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(eaten)").font(.sans(20, weight: .bold)).contentTransition(.numericText())
                Text("/\(target)g").font(.sans(13)).foregroundStyle(.secondary)
            }
        }
    }

    private func mealCardMac(_ meal: Binding<Meal>) -> some View {
        let m = meal.wrappedValue
        return Group {
            if m.eaten {
                HStack(spacing: 0) {
                    ZStack {
                        m.tint.opacity(0.16)
                        Image(systemName: m.icon).font(.system(size: 40)).foregroundStyle(m.tint)
                    }
                    .frame(width: 148)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(m.slot).font(.serifDisplay(30))
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) { meal.wrappedValue.eaten = false }
                            } label: {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(Color.green500)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(m.name).font(.sans(14)).foregroundStyle(.secondary).lineLimit(1)
                        Spacer()
                        (Text("\(m.kcal)").font(.sans(40, weight: .bold))
                         + Text(" kcal").font(.sans(13)).foregroundStyle(.secondary))
                    }
                    .padding(24)
                }
                .frame(height: 208)
                .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 14, y: 5)
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(m.slot).font(.serifDisplay(30)).foregroundStyle(.primary.opacity(0.55))
                        Text(m.slot == "Dinner" ? "Target: ~\(m.kcal) kcal to hit your goal" : "Recommended ~\(m.kcal) kcal")
                            .font(.sans(14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack {
                        if m.slot == "Dinner" {
                            Text("—  —  —").font(.sans(30, weight: .bold)).foregroundStyle(.secondary.opacity(0.35))
                            Spacer()
                        }
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { meal.wrappedValue.eaten = true }
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                                Text("Log \(m.slot)").font(.sans(14, weight: .bold))
                            }
                            .foregroundStyle(m.slot == "Dinner" ? .white : Color.green700)
                            .frame(maxWidth: m.slot == "Dinner" ? nil : .infinity)
                            .padding(.horizontal, m.slot == "Dinner" ? 26 : 0)
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
                }
                .padding(24)
                .frame(height: 208, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )
            }
        }
    }
    #endif

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

                // Shopping list — prominent, right under the day summary
                shoppingCTA
                    .slideIn(delay: 0.14)

                // Meal cards
                VStack(spacing: Spacing.md) {
                    ForEach(Array(meals.enumerated()), id: \.element.id) { i, meal in
                        mealCardIOS($meals[i])
                            .slideIn(delay: 0.18 + Double(i) * 0.06)
                    }
                }
                .padding(.top, Spacing.md)

                // Recipes section
                HStack {
                    Text("RECIPES")
                        .font(.sans(11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .kerning(1.3)
                    Spacer()
                    NavigationLink(destination: RecipesView()) {
                        Text("See all")
                            .font(.sans(13, weight: .semibold))
                            .foregroundStyle(Color.green500)
                    }
                }
                .padding(.top, Spacing.md)
                .slideIn(delay: 0.42)

                NavigationLink(destination: RecipesView()) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.green500)
                            .frame(width: 44, height: 44)
                            .background(Color.green500.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add from TikTok / IG / YouTube")
                                .font(.sans(15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("AI extracts the recipe in seconds")
                                .font(.sans(13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(Spacing.md)
                    .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .slideIn(delay: 0.46)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth()
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: eatenKcal)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
        .sheet(isPresented: $showShopping) { ShoppingSheet(isPresented: $showShopping) }
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

// Presents the shopping list in a sheet with a close button (works on both platforms)
private struct ShoppingSheet: View {
    @Binding var isPresented: Bool
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ShoppingView()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(11)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(Spacing.md)
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 680)
        #endif
    }
}
