import Foundation

// Aspirational sample data for App Store screenshots. DEBUG-only, off unless the
// app is launched with `-BB_DEMO 1` (SIMCTL_CHILD_BB_DEMO=1). It never ships:
// `isActive` is compiled to a constant `false` in release, so every call site
// folds away and no demo write can reach a real user's data.
//
// Two mechanisms, because the screens split two ways:
//  - Streak / sessions / this-week / milestones all derive from TrainingStore's
//    `sbp-tp-progress` dict, so `seedIfActive()` writes ONE realistic progress
//    history and Today, Training, Progress and Account all light up together.
//  - Nutrition macros, steps, weight and rank are hard-coded literals in the
//    views, so those read `DemoData.isActive ? demoValue : realValue` inline.
//
// Numbers are kept mutually consistent: the Today nutrition ring equals the sum
// of the meals marked eaten on the Meals tab.
enum DemoData {
    #if DEBUG
    static let isActive = ProcessInfo.processInfo.environment["BB_DEMO"] == "1"
    #else
    static let isActive = false
    #endif

    // Nutrition — a believable mid-afternoon: breakfast + lunch + snack logged,
    // dinner still to come. Sum matches the three eaten meals in MealsView.
    static let kcalConsumed = 1370
    static let kcalTarget   = 2600
    static let protein = (value: 105, target: 160)
    static let carbs   = (value: 156, target: 300)
    static let fat     = (value: 35,  target: 80)

    static let stepsText  = "8,240"
    static let weightText = "72.4"
    static let waterL     = 1.75
    static let sessionsThisMonthText = "18"

    // Aspirational but earned: Gold, division 2 — consistent with ~35 sessions.
    static var rank: RankState {
        RankState(tier: .gold, xp: 900, xpForNext: 1400, level: 8, division: 2)
    }

    // Meals with the first three slots marked eaten (only when active).
    static func applyEaten(_ meals: [Meal]) -> [Meal] {
        guard isActive else { return meals }
        return meals.enumerated().map { i, m in
            var m = m; m.eaten = i < 3; return m
        }
    }

    // Writes a realistic training history into the same UserDefaults keys the
    // stores read, so it must run before the store singletons first load. Yields
    // a current 5-day streak and ~35 total sessions.
    static func seedIfActive() {
        guard isActive else { return }
        let d = UserDefaults.standard
        let cal = Calendar.current
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"; iso.locale = Locale(identifier: "en_US_POSIX")
        func key(_ off: Int) -> String? {
            cal.date(byAdding: .day, value: -off, to: Date()).map { iso.string(from: $0) }
        }

        var progress: [String: Bool] = [:]
        // Current 5-day streak: today + previous four.
        for off in 0...4 { if let k = key(off) { progress[k] = true } }
        // ~30 more sessions across prior weeks. The gap at offsets 5-6 (this
        // week's Mon/Sun) is deliberate — it stops the streak at five.
        for w in 1...6 { for j in 0...4 { if let k = key(7 * w + j) { progress[k] = true } } }
        if let data = try? JSONEncoder().encode(progress) {
            d.set(data, forKey: "sbp-tp-progress")
        }

        // Today's hydration + creatine, for the Today tab tiles.
        if let k = key(0) {
            let logs = [k: TodayLog(water: waterL, creatine: true, junk: [])]
            if let data = try? JSONEncoder().encode(logs) {
                d.set(data, forKey: "sbp-today")
            }
        }
    }
}
