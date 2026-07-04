import SwiftUI

// Editable week plan used by the onboarding preview step (Hevy-style)

struct OnbExercise: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var selected: Bool
}

struct OnbPlanDay: Identifiable, Equatable {
    let id = UUID()
    let label: String          // Mon…Sun
    var focus: String          // "Push", "Rest", …
    var exercises: [OnbExercise]

    var isRest: Bool { focus == "Rest" }
    var selectedCount: Int { exercises.filter(\.selected).count }
}

enum PlanBuilder {
    static let focusOptions = ["Push", "Pull", "Legs", "Upper", "Lower", "Full Body", "Rest"]

    // Sample exercise library per focus — first 5 pre-selected
    static let library: [String: [String]] = [
        "Push":      ["Bench Press", "Incline DB Press", "Overhead Press", "Cable Fly", "Lateral Raise", "Triceps Pushdown", "Dips"],
        "Pull":      ["Deadlift", "Pull-Ups", "Barbell Row", "Lat Pulldown", "Face Pull", "Barbell Curl", "Hammer Curl"],
        "Legs":      ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Leg Extension", "Calf Raise", "Walking Lunge"],
        "Upper":     ["Bench Press", "Barbell Row", "Overhead Press", "Lat Pulldown", "Lateral Raise", "Barbell Curl", "Triceps Pushdown"],
        "Lower":     ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Hip Thrust", "Calf Raise"],
        "Full Body": ["Squat", "Bench Press", "Barbell Row", "Overhead Press", "Romanian Deadlift", "Pull-Ups"]
    ]

    static func exercises(for focus: String) -> [OnbExercise] {
        guard let names = library[focus] else { return [] }
        return names.enumerated().map { i, name in
            OnbExercise(name: name, selected: i < 5)
        }
    }

    // Default week from the chosen training-days count
    static func defaultWeek(days: Int) -> [OnbPlanDay] {
        let split: [(String, String)]
        switch days {
        case 3:
            split = [("Mon", "Full Body"), ("Tue", "Rest"), ("Wed", "Full Body"), ("Thu", "Rest"), ("Fri", "Full Body"), ("Sat", "Rest"), ("Sun", "Rest")]
        case 4:
            split = [("Mon", "Upper"), ("Tue", "Lower"), ("Wed", "Rest"), ("Thu", "Upper"), ("Fri", "Lower"), ("Sat", "Rest"), ("Sun", "Rest")]
        case 5:
            split = [("Mon", "Push"), ("Tue", "Pull"), ("Wed", "Legs"), ("Thu", "Rest"), ("Fri", "Upper"), ("Sat", "Lower"), ("Sun", "Rest")]
        default:
            split = [("Mon", "Push"), ("Tue", "Pull"), ("Wed", "Legs"), ("Thu", "Push"), ("Fri", "Pull"), ("Sat", "Legs"), ("Sun", "Rest")]
        }
        return split.map { day, focus in
            OnbPlanDay(label: day, focus: focus, exercises: exercises(for: focus))
        }
    }
}
