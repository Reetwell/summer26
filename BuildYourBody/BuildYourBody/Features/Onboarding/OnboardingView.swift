import SwiftUI

// First-run onboarding — mirrors the web app's flow:
// goal → training days → location → meals per day → plan preview
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var goal: String?
    @State private var days: Int?
    @State private var location: String?
    @State private var mealsPerDay: Int?
    @State private var plan: [OnbPlanDay] = []
    @State private var planBuiltFor: Int?
    @State private var expandedDay: UUID?
    @State private var pickerDayID: UUID?

    private let totalSteps = 5

    init(startStep: Int = 0, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _step = State(initialValue: startStep)
        #if DEBUG
        // Test hook: BB_ONB_STEP preloads a step with sample answers for screenshots
        if let s = ProcessInfo.processInfo.environment["BB_ONB_STEP"], let n = Int(s) {
            _step = State(initialValue: n)
            _goal = State(initialValue: "Build muscle")
            _days = State(initialValue: 4)
            _location = State(initialValue: "Gym")
            _mealsPerDay = State(initialValue: 4)
        }
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Step content slides horizontally
            Group {
                switch step {
                case 0: goalStep
                case 1: daysStep
                case 2: locationStep
                case 3: mealsStep
                default: previewStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step)

            footer
        }
        .background(Color.bbBackground)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: step)
        .sheet(isPresented: Binding(
            get: { pickerDayID != nil },
            set: { if !$0 { pickerDayID = nil } }
        )) {
            if let idx = plan.firstIndex(where: { $0.id == pickerDayID }) {
                ExercisePickerView(day: $plan[idx])
            }
        }
    }

    // MARK: header / footer

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                if step > 0 {
                    Button {
                        step -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bbSurface, in: Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.opacity)
                }
                Spacer()
                Text("\(step + 1) of \(totalSteps)")
                    .font(.sans(12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.green500.opacity(0.14))
                    Capsule().fill(Color.green500)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: 640)
    }

    private var canContinue: Bool {
        switch step {
        case 0: return goal != nil
        case 1: return days != nil
        case 2: return location != nil
        case 3: return mealsPerDay != nil
        default: return true
        }
    }

    private var footer: some View {
        BBButton(title: step == totalSteps - 1 ? "Build my plan" : "Continue") {
            if step == totalSteps - 1 {
                onComplete()
            } else {
                step += 1
            }
        }
        .opacity(canContinue ? 1 : 0.4)
        .disabled(!canContinue)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: 640)
        .animation(.easeOut(duration: 0.18), value: canContinue)
    }

    // MARK: steps

    private var goalStep: some View {
        stepLayout(
            title: "What's your goal?",
            subtitle: "This shapes your training and calories."
        ) {
            optionCard("Lose fat", icon: "flame.fill", detail: "Calorie deficit, keep muscle", selected: goal == "Lose fat") { goal = "Lose fat" }
            optionCard("Build muscle", icon: "figure.strengthtraining.traditional", detail: "Lean surplus, progressive overload", selected: goal == "Build muscle") { goal = "Build muscle" }
            optionCard("Get stronger", icon: "bolt.fill", detail: "Strength focus, heavier lifts", selected: goal == "Get stronger") { goal = "Get stronger" }
            optionCard("Stay fit", icon: "heart.fill", detail: "Balanced training and eating", selected: goal == "Stay fit") { goal = "Stay fit" }
        }
    }

    private var daysStep: some View {
        stepLayout(
            title: "How many days can you train?",
            subtitle: "Be honest — consistency beats ambition."
        ) {
            HStack(spacing: Spacing.sm) {
                ForEach([3, 4, 5, 6], id: \.self) { n in
                    Button {
                        days = n
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(n)")
                                .font(.serifDisplay(30))
                            Text("days")
                                .font(.sans(12))
                                .foregroundStyle(days == n ? Color.green700 : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            days == n ? Color.green500.opacity(0.14) : Color.bbSurface,
                            in: RoundedRectangle(cornerRadius: Radius.lg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(days == n ? Color.green500 : .clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(days == n ? Color.green700 : .primary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            if let days {
                Text(splitName(for: days))
                    .font(.sans(13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.sm)
                    .transition(.opacity)
            }
        }
    }

    private var locationStep: some View {
        stepLayout(
            title: "Where do you train?",
            subtitle: "We'll pick exercises that fit your kit."
        ) {
            optionCard("Gym", icon: "building.2.fill", detail: "Full equipment — barbells, machines, cables", selected: location == "Gym") { location = "Gym" }
            optionCard("Home", icon: "house.fill", detail: "Dumbbells, bands and bodyweight", selected: location == "Home") { location = "Home" }
            optionCard("Bodyweight only", icon: "figure.core.training", detail: "No equipment needed", selected: location == "Bodyweight only") { location = "Bodyweight only" }
        }
    }

    private var mealsStep: some View {
        stepLayout(
            title: "How do you like to eat?",
            subtitle: "We'll build your meal plan around this."
        ) {
            optionCard("3 meals", icon: "fork.knife", detail: "Breakfast, lunch, dinner — bigger plates", selected: mealsPerDay == 3) { mealsPerDay = 3 }
            optionCard("3 meals + snack", icon: "takeoutbag.and.cup.and.straw.fill", detail: "The classic — most popular", selected: mealsPerDay == 4) { mealsPerDay = 4 }
            optionCard("5 small meals", icon: "clock.fill", detail: "Grazing through the day", selected: mealsPerDay == 5) { mealsPerDay = 5 }
        }
    }

    private var previewStep: some View {
        stepLayout(
            title: "Build your week",
            subtitle: "Name your days, pick a template, add your exercises."
        ) {
            ForEach($plan) { $day in
                planDayCard($day)
            }

            // Macro targets preview
            BBCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("DAILY TARGETS")
                        .font(.sans(10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(1.2)
                    HStack {
                        targetStat("2,600", "kcal")
                        Divider().frame(height: 30)
                        targetStat("160g", "protein")
                        Divider().frame(height: 30)
                        targetStat("\(mealsPerDay ?? 4)", "meals/day")
                    }
                }
            }
            .padding(.top, Spacing.xs)

            Text("You can tweak everything later.")
                .font(.sans(12))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
        }
        .onAppear {
            if plan.isEmpty || planBuiltFor != days {
                plan = PlanBuilder.defaultWeek(days: days ?? 4)
                planBuiltFor = days
            }
        }
    }

    // MARK: plan editor (Hevy-style)

    private func planDayCard(_ day: Binding<OnbPlanDay>) -> some View {
        let d = day.wrappedValue
        let isExpanded = expandedDay == d.id && !d.isRest

        return BBCard(padding: Spacing.sm) {
            VStack(spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    // Day chip
                    Text(d.label)
                        .font(.sans(12, weight: .bold))
                        .foregroundStyle(d.isRest ? Color.secondary : Color.green700)
                        .frame(width: 40, height: 40)
                        .background(
                            d.isRest ? Color.secondary.opacity(0.08) : Color.green500.opacity(0.13),
                            in: RoundedRectangle(cornerRadius: Radius.md)
                        )

                    if d.isRest {
                        Text("Rest day")
                            .font(.sans(15))
                            .foregroundStyle(.secondary)
                    } else {
                        // Editable workout name — call it whatever fits your split
                        VStack(alignment: .leading, spacing: 1) {
                            TextField("Workout name", text: day.name)
                                .font(.sans(15, weight: .semibold))
                                .textFieldStyle(.plain)
                            Text("\(d.exercises.count) exercises")
                                .font(.sans(12))
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer()

                    if !d.isRest {
                        // Expand chevron
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                expandedDay = isExpanded ? nil : d.id
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.green500)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .frame(width: 30, height: 30)
                                .background(Color.green500.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    // Day menu: templates + rest toggle
                    Menu {
                        Section("Start from a template") {
                            ForEach(PlanBuilder.templates, id: \.self) { template in
                                Button(template) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        day.wrappedValue.isRest = false
                                        day.wrappedValue.name = template
                                        day.wrappedValue.exercises = PlanBuilder.exercises(for: template)
                                    }
                                }
                            }
                        }
                        Section {
                            if d.isRest {
                                Button("Make it a training day") {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        day.wrappedValue.isRest = false
                                        day.wrappedValue.name = "Workout"
                                        day.wrappedValue.exercises = []
                                    }
                                }
                            } else {
                                Button("Make it a rest day", role: .destructive) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        day.wrappedValue.isRest = true
                                        day.wrappedValue.name = "Rest"
                                        day.wrappedValue.exercises = []
                                        if expandedDay == d.id { expandedDay = nil }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.secondary.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Exercise list + add button
                if isExpanded {
                    VStack(spacing: 0) {
                        Divider().padding(.vertical, Spacing.sm)

                        ForEach(d.exercises) { exercise in
                            HStack(spacing: Spacing.sm) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(exercise.name)
                                        .font(.sans(14, weight: .medium))
                                    Text(exercise.muscle)
                                        .font(.sans(11))
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Text("3 sets")
                                    .font(.sans(12))
                                    .foregroundStyle(.tertiary)
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        day.wrappedValue.exercises.removeAll { $0.id == exercise.id }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 17))
                                        .foregroundStyle(Color.secondary.opacity(0.35))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 7)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Add from the full library
                        Button {
                            pickerDayID = d.id
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 17))
                                Text("Add exercise")
                                    .font(.sans(14, weight: .semibold))
                            }
                            .foregroundStyle(Color.green500)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.green500.opacity(0.09), in: RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, Spacing.xs)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(isExpanded ? Color.green500.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }

    // MARK: helpers

    private func stepLayout<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(.serifDisplay(30))
                Text(subtitle)
                    .font(.sans(14))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, Spacing.md)

                content()
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private func optionCard(_ title: String, icon: String, detail: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(selected ? .white : Color.green500)
                    .frame(width: 42, height: 42)
                    .background(
                        selected ? Color.green500 : Color.green500.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Radius.md)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.sans(16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(selected ? Color.green500 : Color.secondary.opacity(0.3))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(Spacing.md)
            .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(selected ? Color.green500 : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selected)
    }

    private func targetStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.serifDisplay(20))
            Text(label)
                .font(.sans(11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func splitName(for days: Int) -> String {
        switch days {
        case 3: return "We'd recommend: Full Body ×3 — high frequency, big lifts"
        case 4: return "We'd recommend: Upper / Lower ×2 — the sweet spot"
        case 5: return "We'd recommend: Push / Pull / Legs + Upper / Lower"
        default: return "We'd recommend: Push / Pull / Legs ×2 — serious volume"
        }
    }

}
