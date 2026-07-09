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
    private let ts = TrainingStore.shared
    @State private var showSession = false
    @State private var showPlanDetails = false

    // Computed from live store
    private var liveWeek: [WeekDayState] {
        var cal = Calendar.current; cal.firstWeekday = 2
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        let fmt = DateFormatter(); fmt.dateFormat = "E"; fmt.locale = Locale(identifier: "en_US_POSIX")
        let phase = ts.plan.phases[safe: ts.activePhaseIndex]
        return (0..<7).compactMap { off -> WeekDayState? in
            guard let d = cal.date(byAdding: .day, value: off, to: start) else { return nil }
            let letter = String(fmt.string(from: d).prefix(1))
            let session = phase?.sessions.first { $0.day == fmt.string(from: d) }
            let isRest = session?.focus == "Rest" || session == nil
            let isToday = cal.isDateInToday(d)
            let isDone = ts.progress[ts.isoDate(d)] == true
            let state: WeekDayState.DayState = isDone ? .done : (isToday ? .today : (isRest ? .rest : .upcoming))
            return WeekDayState(letter: letter, state: state)
        }
    }

    private var phaseBadge: String {
        ts.todayPhase.map { "\($0.badge) · WK \($0.weeks)" } ?? "No plan"
    }

    private var routines: [Routine] {
        guard let phase = ts.plan.phases[safe: ts.activePhaseIndex] else { return [] }
        return phase.sessions
            .filter { $0.focus != "Rest" }
            .map { Routine(name: $0.name, exercises: $0.exercises, duration: $0.duration) }
    }

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    private var iosLayout: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header
                    HStack(alignment: .firstTextBaseline) {
                        Text("Training")
                            .font(.serifDisplay(34))
                        Spacer()
                        NavigationLink(destination: PlanDetailsView()) {
                            Text(phaseBadge.uppercased())
                                .font(.sans(11, weight: .bold))
                                .foregroundStyle(Color.green500)
                                .kerning(0.8)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green500.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .slideIn()

                    // TODAY hero
                    todayHero
                        .slideIn(delay: 0.06)

                    // Week strip — live
                    BBCard(padding: Spacing.sm) {
                        HStack {
                            ForEach(liveWeek) { day in
                                weekDot(day)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .slideIn(delay: 0.12)

                    // Readiness
                    ReadinessBannerView()
                        .slideIn(delay: 0.16)

                    // Quick stats — live
                    HStack(spacing: Spacing.sm) {
                        statCard(value: "\(ts.sessionsThisWeek)/\(ts.sessionsPlannedThisWeek)", unit: "", label: "sessions this week")
                        statCard(value: "\(ts.currentStreak)", unit: "🔥", label: "day streak")
                        NavigationLink(destination: PlanDetailsView()) {
                            statCard(value: "\(ts.plan.phases.count)", unit: "", label: "phases in plan")
                        }
                        .buttonStyle(.plain)
                    }
                    .slideIn(delay: 0.22)

                    // Routines
                    HStack {
                        Text("THIS WEEK'S SESSIONS")
                            .font(.sans(11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .kerning(1.2)
                        Spacer()
                        NavigationLink(destination: PlanDetailsView()) {
                            Text("Plan details")
                                .font(.sans(13, weight: .semibold))
                                .foregroundStyle(Color.green500)
                        }
                    }
                    .padding(.top, 4)
                    .slideIn(delay: 0.24)

                    ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                        let session = ts.plan.phases[safe: ts.activePhaseIndex]?.sessions.first { $0.name == routine.name }
                        NavigationLink(destination: session.map { s in
                            SessionView(session: s, phase: ts.todayPhase ?? ts.plan.phases[0])
                        }) {
                            routineCard(routine)
                        }
                        .buttonStyle(.plain)
                        .slideIn(delay: 0.26 + Double(index) * 0.05)
                    }
                }
                .padding(Spacing.md)
                .readableWidth()
            }
            .background(Color.bbBackground)
            .hideNavigationBar()
        }
    }

    @ViewBuilder
    private var todayHero: some View {
        if let session = ts.todaySession(), session.focus != "Rest" {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("TODAY · \(Date().formatted(.dateTime.weekday(.wide)).uppercased())")
                        .font(.sans(10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .kerning(1.2)
                    Spacer()
                    if ts.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").font(.system(size: 11))
                            Text("\(ts.currentStreak)").font(.sans(12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.name).font(.serifDisplay(30)).foregroundStyle(.white)
                    Text("\(session.exercises.count) exercises · \(session.duration)")
                        .font(.sans(13)).foregroundStyle(.white.opacity(0.8))
                }

                if ts.isDone() {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundStyle(.white)
                        Text("Done today — great work").font(.sans(14, weight: .semibold)).foregroundStyle(.white)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: Radius.md))
                } else {
                    NavigationLink(destination: SessionView(session: session, phase: ts.todayPhase ?? ts.plan.phases[0])) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill").font(.system(size: 14))
                            Text("Start workout").font(.sans(16, weight: .bold))
                        }
                        .foregroundStyle(Color.green700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white, in: RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: Radius.lg)
            )
        } else {
            BBCard {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "zzz")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.green500.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .background(Color.green500.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest day").font(.sans(16, weight: .semibold))
                        Text("Recovery is part of the plan.").font(.sans(13)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    #if os(macOS)
    // MARK: - macOS bento layout (Stitch-inspired: date rail + data headline + grid)

    private struct RailDay: Identifiable {
        let id = UUID()
        let label: String
        let num: Int
        let kind: String   // PUSH / LEGS / REST …
        let state: WeekDayState.DayState
    }

    private let railWeek: [RailDay] = [
        .init(label: "MON", num: 12, kind: "PUSH", state: .done),
        .init(label: "TUE", num: 13, kind: "PULL", state: .done),
        .init(label: "WED", num: 14, kind: "REST", state: .rest),
        .init(label: "TODAY", num: 15, kind: "PUSH", state: .today),
        .init(label: "FRI", num: 16, kind: "LEGS", state: .upcoming),
        .init(label: "SAT", num: 17, kind: "PULL", state: .upcoming),
        .init(label: "SUN", num: 18, kind: "REST", state: .rest)
    ]

    private struct Lift: Identifiable {
        let id = UUID(); let name: String; let kg: String; let frac: CGFloat; let delta: String
    }
    private let topLifts: [Lift] = [
        .init(name: "Bench Press", kg: "80", frac: 0.78, delta: "+5 kg"),
        .init(name: "Squat", kg: "110", frac: 0.64, delta: "+10 kg"),
        .init(name: "Deadlift", kg: "140", frac: 0.71, delta: "+7.5 kg"),
        .init(name: "Overhead Press", kg: "52.5", frac: 0.55, delta: "+2.5 kg")
    ]

    private struct PR: Identifiable {
        let id = UUID(); let name: String; let detail: String; let kg: String
    }
    private let prs: [PR] = [
        .init(name: "Bench Press", detail: "Tuesday · +5 kg", kg: "80 kg"),
        .init(name: "Lat Pulldown", detail: "Monday · +5 kg", kg: "65 kg"),
        .init(name: "Leg Press", detail: "Monday · +10 kg", kg: "180 kg")
    ]

    private var macLayout: some View {
        HStack(spacing: 0) {
            dateRail
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Data headline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEEK 3 OF 6 · HYPERTROPHY PHASE")
                            .font(.sans(11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .kerning(1.6)
                        (Text("12,400 kg").foregroundStyle(Color.green700)
                         + Text("\nlifted this week.").foregroundStyle(.primary))
                            .font(.serifDisplay(52))
                            .lineSpacing(2)
                    }
                    .slideIn()

                    // Stats strip
                    HStack(spacing: 40) {
                        macStat("SESSIONS", "4", sub: "/ 5")
                        macStat("NEW PRS", "3", up: "↑")
                        macStat("STREAK", "6", sub: "days")
                        macStat("VS LAST WEEK", "", up: "+8%")
                        macStat("TIME UNDER LOAD", "3h 42m")
                    }
                    .slideIn(delay: 0.05)

                    // Readiness inline (macOS — compact, no hero)
                    ReadinessBannerView()
                        .slideIn(delay: 0.08)

                    // Bento grid
                    let cols = [GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.fixed(300), spacing: 16)]
                    LazyVGrid(columns: cols, alignment: .leading, spacing: 16) {
                        heroCard.gridCellColumns(2)
                        rightStack
                        topLiftsCard
                        prsCard
                        macRoutinesCard
                    }
                    .slideIn(delay: 0.1)
                }
                .padding(48)
                .frame(maxWidth: 1180, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.bbBackground)
    }

    private var dateRail: some View {
        VStack(spacing: 0) {
            ForEach(Array(railWeek.enumerated()), id: \.element.id) { i, day in
                VStack(spacing: 3) {
                    Text(day.label)
                        .font(.sans(11, weight: .bold))
                        .kerning(1.4)
                        .foregroundStyle(day.state == .today ? Color.green500 : Color.secondary.opacity(0.7))
                    Text("\(day.num)")
                        .font(.serifDisplay(day.state == .today ? 44 : 38))
                        .foregroundStyle(day.state == .today ? Color.green700 : (day.state == .rest ? Color.secondary.opacity(0.5) : .primary.opacity(0.85)))
                    Group {
                        if day.state == .done {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green500)
                        } else {
                            Text(day.kind)
                                .foregroundStyle(day.state == .today ? Color.green500 : .secondary)
                        }
                    }
                    .font(.sans(9, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    if day.state == .today {
                        Capsule().fill(Color.green500).frame(width: 3, height: 44).offset(x: 6)
                    }
                }
                if i < railWeek.count - 1 { Spacer(minLength: 14) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
        .frame(width: 128)
        .background(Color.bbSurface)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY · PUSH DAY A")
                .font(.sans(11, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .kerning(1.4)
            Text("Chest, shoulders & triceps")
                .font(.serifDisplay(34))
                .foregroundStyle(.white)
                .padding(.top, 8)
            Text("6 exercises · ~55 min")
                .font(.sans(14))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 4)

            // Exercise chips
            HStack(spacing: 8) {
                ForEach(["Bench Press", "Incline DB Press", "Overhead Press", "+3 more"], id: \.self) { c in
                    Text(c)
                        .font(.sans(12.5))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13).padding(.vertical, 7)
                        .background(.white.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
                }
            }
            .padding(.vertical, 18)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Button {} label: {
                    HStack(spacing: 9) {
                        Image(systemName: "play.fill").font(.system(size: 13))
                        Text("Start workout").font(.sans(15, weight: .bold))
                    }
                    .foregroundStyle(Color.green900)
                    .padding(.horizontal, 26).padding(.vertical, 14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                Text("Last time: 12,400 kg · beat it")
                    .font(.sans(13))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 270, alignment: .topLeading)
        .background(
            LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var rightStack: some View {
        VStack(spacing: 16) {
            BBCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("SESSIONS THIS WEEK").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(Color.green500.opacity(0.13), lineWidth: 8)
                            Circle().trim(from: 0, to: 0.8)
                                .stroke(Color.green500, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("80%").font(.serifDisplay(17))
                        }
                        .frame(width: 66, height: 66)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("4/5").font(.serifDisplay(28))
                            Text("1 to go — Saturday").font(.sans(12.5)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            BBCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VOLUME TREND").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("12.4k").font(.serifDisplay(28))
                        Text("kg").font(.sans(14)).foregroundStyle(.secondary)
                    }
                    Sparkline()
                        .stroke(Color.green500, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(height: 40)
                    HStack(spacing: 4) {
                        Text("+8%").font(.sans(12.5, weight: .bold)).foregroundStyle(Color.green500)
                        Text("vs last week").font(.sans(12.5)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var topLiftsCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("TOP LIFTS · PROGRESS").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                    .padding(.bottom, 12)
                ForEach(topLifts) { lift in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(lift.name).font(.sans(14.5, weight: .medium))
                                Spacer()
                                (Text(lift.kg).font(.serifDisplay(19))
                                 + Text(" kg").font(.sans(12)).foregroundStyle(.secondary))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.green500.opacity(0.12))
                                    Capsule().fill(Color.green500).frame(width: geo.size.width * lift.frac)
                                }
                            }
                            .frame(height: 5)
                        }
                        Text(lift.delta)
                            .font(.sans(12, weight: .bold))
                            .foregroundStyle(Color.green500)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Color.green500.opacity(0.1), in: Capsule())
                    }
                    .padding(.vertical, 11)
                    if lift.id != topLifts.last?.id { Divider() }
                }
            }
        }
    }

    private var prsCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("NEW RECORDS THIS WEEK").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                    .padding(.bottom, 6)
                ForEach(prs) { pr in
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#B47A17"))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "#E8A13A").opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pr.name).font(.sans(14, weight: .medium))
                            Text(pr.detail).font(.sans(12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(pr.kg).font(.serifDisplay(19))
                    }
                    .padding(.vertical, 10)
                    if pr.id != prs.last?.id { Divider() }
                }
                Text("Next target: Squat 115 kg — you're close.")
                    .font(.sans(12.5)).foregroundStyle(.secondary)
                    .padding(.top, 12)
            }
        }
    }

    private var macRoutinesCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("YOUR ROUTINES").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                    .padding(.bottom, 8)
                ForEach(routines) { r in
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.green700)
                            .frame(width: 36, height: 36)
                            .background(Color.green500.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.name).font(.sans(14.5, weight: .semibold))
                            Text("\(r.exercises.count) exercises · \(r.duration)").font(.sans(12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    if r.id != routines.last?.id { Divider() }
                }
                Button {} label: {
                    Text("+ New routine")
                        .font(.sans(13.5, weight: .bold))
                        .foregroundStyle(Color.green700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.green500.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.green500.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4])))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 12)
            }
        }
    }

    private func macStat(_ key: String, _ value: String, sub: String = "", up: String = "") -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key).font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if !value.isEmpty { Text(value).font(.sans(20, weight: .bold)) }
                if !sub.isEmpty { Text(sub).font(.sans(13)).foregroundStyle(.secondary) }
                if !up.isEmpty { Text(up).font(.sans(14, weight: .bold)).foregroundStyle(Color.green500) }
            }
        }
    }
    #endif

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
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(routine.name)
                        .font(.sans(16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(routine.exercises.count) ex · \(routine.duration)")
                        .font(.sans(12))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                Text(previewLine(routine))
                    .font(.sans(13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func previewLine(_ routine: Routine) -> String {
        let first = routine.exercises.prefix(3).joined(separator: " · ")
        let rest = routine.exercises.count - 3
        return rest > 0 ? "\(first)  +\(rest) more" : first
    }
}

#if os(macOS)
// Rising volume sparkline
struct Sparkline: Shape {
    func path(in rect: CGRect) -> Path {
        let pts: [CGFloat] = [0.72, 0.60, 0.66, 0.44, 0.52, 0.24, 0.16]
        var p = Path()
        for (i, v) in pts.enumerated() {
            let x = rect.width * CGFloat(i) / CGFloat(pts.count - 1)
            let y = rect.height * v
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}
#endif
