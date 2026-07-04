import SwiftUI

// Editable week plan used by the onboarding preview step (Hevy-style)

struct OnbExercise: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let muscle: String
}

struct OnbPlanDay: Identifiable, Equatable {
    let id = UUID()
    let label: String          // Mon…Sun
    var name: String           // user-editable: "Chest Shoulder Triceps"
    var isRest: Bool
    var exercises: [OnbExercise]
}

enum PlanBuilder {
    static let templates = ["Push", "Pull", "Legs", "Upper", "Lower", "Full Body"]

    // Full exercise library grouped by muscle — the "long list"
    static let library: [(muscle: String, exercises: [String])] = [
        ("Chest", ["Bench Press", "Incline Bench Press", "Incline DB Press", "DB Fly", "Cable Fly", "Machine Chest Press", "Push-Ups", "Dips"]),
        ("Back", ["Deadlift", "Pull-Ups", "Chin-Ups", "Barbell Row", "DB Row", "Lat Pulldown", "Seated Cable Row", "T-Bar Row", "Face Pull", "Straight-Arm Pulldown"]),
        ("Shoulders", ["Overhead Press", "DB Shoulder Press", "Arnold Press", "Lateral Raise", "Cable Lateral Raise", "Front Raise", "Rear Delt Fly", "Upright Row"]),
        ("Biceps", ["Barbell Curl", "DB Curl", "Hammer Curl", "Preacher Curl", "Incline DB Curl", "Cable Curl"]),
        ("Triceps", ["Triceps Pushdown", "Skull Crushers", "Overhead Extension", "Close-Grip Bench", "Cable Kickback"]),
        ("Legs", ["Squat", "Front Squat", "Hack Squat", "Leg Press", "Romanian Deadlift", "Leg Curl", "Leg Extension", "Walking Lunge", "Bulgarian Split Squat", "Hip Thrust", "Standing Calf Raise", "Seated Calf Raise"]),
        ("Core", ["Plank", "Hanging Leg Raise", "Cable Crunch", "Ab Wheel Rollout", "Russian Twist"])
    ]

    static func find(_ name: String) -> OnbExercise? {
        for group in library {
            if group.exercises.contains(name) {
                return OnbExercise(name: name, muscle: group.muscle)
            }
        }
        return nil
    }

    // Starter exercises per template
    static func exercises(for template: String) -> [OnbExercise] {
        let names: [String]
        switch template {
        case "Push":      names = ["Bench Press", "Incline DB Press", "Overhead Press", "Lateral Raise", "Triceps Pushdown"]
        case "Pull":      names = ["Deadlift", "Pull-Ups", "Barbell Row", "Face Pull", "Barbell Curl"]
        case "Legs":      names = ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Standing Calf Raise"]
        case "Upper":     names = ["Bench Press", "Barbell Row", "Overhead Press", "Lat Pulldown", "Barbell Curl", "Triceps Pushdown"]
        case "Lower":     names = ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Hip Thrust", "Standing Calf Raise"]
        case "Full Body": names = ["Squat", "Bench Press", "Barbell Row", "Overhead Press", "Romanian Deadlift"]
        default:          names = []
        }
        return names.compactMap(find)
    }

    // Default week from the chosen training-days count
    static func defaultWeek(days: Int) -> [OnbPlanDay] {
        let split: [(String, String?)]
        switch days {
        case 3:
            split = [("Mon", "Full Body"), ("Tue", nil), ("Wed", "Full Body"), ("Thu", nil), ("Fri", "Full Body"), ("Sat", nil), ("Sun", nil)]
        case 4:
            split = [("Mon", "Upper"), ("Tue", "Lower"), ("Wed", nil), ("Thu", "Upper"), ("Fri", "Lower"), ("Sat", nil), ("Sun", nil)]
        case 5:
            split = [("Mon", "Push"), ("Tue", "Pull"), ("Wed", "Legs"), ("Thu", nil), ("Fri", "Upper"), ("Sat", "Lower"), ("Sun", nil)]
        default:
            split = [("Mon", "Push"), ("Tue", "Pull"), ("Wed", "Legs"), ("Thu", "Push"), ("Fri", "Pull"), ("Sat", "Legs"), ("Sun", nil)]
        }
        return split.map { day, template in
            if let template {
                return OnbPlanDay(label: day, name: template, isRest: false, exercises: exercises(for: template))
            }
            return OnbPlanDay(label: day, name: "Rest", isRest: true, exercises: [])
        }
    }
}
