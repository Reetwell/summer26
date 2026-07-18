import Foundation

// Mirrors web's sbp-tp-progress: { [ISO-date]: true }
// and sbp-trainingplan shape (mode:'phases' | static)

struct TrainingPlan: Codable {
    var mode: String             // "phases"
    var name: String
    var phases: [Phase]

    struct Phase: Codable, Identifiable {
        var id: String
        var name: String
        var badge: String        // "Phase 1 — Fat Loss" etc.
        var weeks: Int
        var sessions: [Session]
    }

    struct Session: Codable, Identifiable {
        var id: String
        var day: String          // "Mon" | "Tue" | ... | "Fri"
        var focus: String        // "Push" | "Pull" | "Legs" | "Rest"
        var name: String         // "Push Day A"
        var exercises: [String]  // exercise names (match Exercise.library)
        var duration: String     // "~55 min"
    }
}

@Observable
final class TrainingStore {
    static let shared = TrainingStore()

    private let progressKey = "sbp-tp-progress"
    private let planKey = "sbp-trainingplan"
    private let phaseKey = "sbp-tp-active-phase"

    private(set) var progress: [String: Bool] = [:]    // ISO date → done
    private(set) var plan: TrainingPlan = .sample
    var activePhaseIndex: Int = 0

    private init() {
        load()
        activePhaseIndex = UserDefaults.standard.integer(forKey: phaseKey)
    }

    // MARK: - Mark done / undone

    func markDone(date: Date = Date()) {
        let k = isoDate(date)
        progress[k] = true
        persistProgress()
    }

    func markUndone(date: Date = Date()) {
        let k = isoDate(date)
        progress.removeValue(forKey: k)
        persistProgress()
    }

    func isDone(_ date: Date = Date()) -> Bool {
        progress[isoDate(date)] == true
    }

    // MARK: - Today's session

    func todaySession() -> TrainingPlan.Session? {
        let today = weekdayShort(Date())
        guard activePhaseIndex < plan.phases.count else { return nil }
        let phase = plan.phases[activePhaseIndex]
        return phase.sessions.first { $0.day == today }
    }

    var todayPhase: TrainingPlan.Phase? {
        guard activePhaseIndex < plan.phases.count else { return nil }
        return plan.phases[activePhaseIndex]
    }

    // MARK: - Stats

    var sessionsThisWeek: Int {
        currentWeekDates().filter { progress[isoDate($0)] == true }.count
    }

    // Total completed sessions ever (real — 0 on a fresh install)
    var totalWorkouts: Int {
        progress.values.filter { $0 }.count
    }

    var sessionsPlannedThisWeek: Int {
        guard activePhaseIndex < plan.phases.count else { return 0 }
        return plan.phases[activePhaseIndex].sessions.filter { $0.focus != "Rest" }.count
    }

    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        for _ in 0..<60 {
            if progress[isoDate(date)] == true {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        // Include today if done
        if progress[isoDate(Date())] == true { streak += 1 }
        return streak
    }

    // Last 7 days of progress for history
    func last7DaysProgress() -> [(date: Date, done: Bool)] {
        (0..<7).compactMap { offset in
            guard let d = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date()) else { return nil }
            return (date: d, done: progress[isoDate(d)] == true)
        }
    }

    // MARK: - Phase management

    func activatePhase(_ index: Int) {
        activePhaseIndex = min(max(0, index), plan.phases.count - 1)
        UserDefaults.standard.set(activePhaseIndex, forKey: phaseKey)
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            progress = decoded
        }
        if let data = UserDefaults.standard.data(forKey: planKey),
           let decoded = try? JSONDecoder().decode(TrainingPlan.self, from: data) {
            plan = decoded
        }
    }

    private func persistProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    // MARK: - Helpers

    private static var isoFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    private static var weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    func isoDate(_ date: Date) -> String { TrainingStore.isoFmt.string(from: date) }
    func weekdayShort(_ date: Date) -> String { TrainingStore.weekdayFmt.string(from: date) }

    private func currentWeekDates() -> [Date] {
        var cal = Calendar.current; cal.firstWeekday = 2
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

// MARK: - Sample plan

extension TrainingPlan {
    static let sample = TrainingPlan(
        mode: "phases",
        name: "Push/Pull/Legs Hypertrophy",
        phases: [
            Phase(id: "p1", name: "Phase 1 — Fat Loss", badge: "Phase 1", weeks: 4, sessions: [
                Session(id: "p1-mon", day: "Mon", focus: "Push",  name: "Push Day A", exercises: ["Bench Press","Overhead Press","Incline DB Press","Lateral Raise","Triceps Pushdown","Cable Fly"], duration: "~55 min"),
                Session(id: "p1-tue", day: "Tue", focus: "Pull",  name: "Pull Day A", exercises: ["Deadlift","Pull-Ups","Barbell Row","Face Pull","Barbell Curl","Hammer Curl"], duration: "~50 min"),
                Session(id: "p1-wed", day: "Wed", focus: "Rest",  name: "Rest", exercises: [], duration: ""),
                Session(id: "p1-thu", day: "Thu", focus: "Legs",  name: "Legs Day", exercises: ["Squat","Romanian Deadlift","Leg Press","Leg Curl","Walking Lunge","Calf Raise"], duration: "~60 min"),
                Session(id: "p1-fri", day: "Fri", focus: "Push",  name: "Push Day B", exercises: ["Incline Bench Press","DB Shoulder Press","Cable Fly","Lateral Raise","Skull Crushers","Dips"], duration: "~55 min"),
                Session(id: "p1-sat", day: "Sat", focus: "Pull",  name: "Pull Day B", exercises: ["Romanian Deadlift","Lat Pulldown","Seated Cable Row","Face Pull","Preacher Curl","Reverse Fly"], duration: "~50 min"),
                Session(id: "p1-sun", day: "Sun", focus: "Rest",  name: "Rest", exercises: [], duration: "")
            ]),
            Phase(id: "p2", name: "Phase 2 — Muscle Build", badge: "Phase 2", weeks: 6, sessions: [
                Session(id: "p2-mon", day: "Mon", focus: "Push",  name: "Upper Body Alpha", exercises: ["Bench Press","Overhead Press","Incline DB Press","Lateral Raise","Triceps Pushdown","Cable Fly"], duration: "~60 min"),
                Session(id: "p2-tue", day: "Tue", focus: "Pull",  name: "Back & Biceps", exercises: ["Deadlift","Pull-Ups","Barbell Row","Face Pull","Barbell Curl","Hammer Curl"], duration: "~55 min"),
                Session(id: "p2-wed", day: "Wed", focus: "Legs",  name: "Legs & Core", exercises: ["Squat","Romanian Deadlift","Leg Press","Leg Curl","Calf Raise","Plank"], duration: "~65 min"),
                Session(id: "p2-thu", day: "Thu", focus: "Rest",  name: "Rest", exercises: [], duration: ""),
                Session(id: "p2-fri", day: "Fri", focus: "Push",  name: "Upper Body Beta", exercises: ["Incline Bench Press","DB Shoulder Press","Cable Fly","Lateral Raise","Skull Crushers","Dips"], duration: "~60 min"),
                Session(id: "p2-sat", day: "Sat", focus: "Pull",  name: "Posterior Chain", exercises: ["Romanian Deadlift","Lat Pulldown","Seated Cable Row","Face Pull","Preacher Curl","Reverse Fly"], duration: "~55 min"),
                Session(id: "p2-sun", day: "Sun", focus: "Rest",  name: "Rest", exercises: [], duration: "")
            ])
        ]
    )
}
