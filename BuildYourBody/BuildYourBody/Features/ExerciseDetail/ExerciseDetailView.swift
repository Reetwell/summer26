import SwiftUI

struct Exercise: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var primaryMuscles: [Muscle]
    var secondaryMuscles: [Muscle]
    var equipment: String          // "barbell" | "dumbbell" | "cable" | "bodyweight" | "machine"
    var instructions: [String]
    var tips: [String]
    var videoURL: String           // embed URL or empty
    var alternatives: [String]     // exercise IDs of same-muscle swaps

    enum Muscle: String, Codable, CaseIterable {
        case chest, shoulders, triceps, biceps, back, lats, traps, core, quads, hamstrings, glutes, calves, forearms
        var displayName: String { rawValue.capitalized }
    }
}

// MARK: - Sample library (replace with Supabase exercise_library table when seeded)

extension Exercise {
    static let library: [Exercise] = [
        Exercise(id: "bench-press", name: "Bench Press",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .triceps],
                 equipment: "barbell",
                 instructions: ["Lie flat on the bench, grip just outside shoulder-width.", "Retract your shoulder blades and arch your lower back slightly.", "Lower the bar to your lower chest with control (~2 sec).", "Drive through your feet and press the bar back up in a slight arc.", "Lock out at the top — don't hyperextend the elbows."],
                 tips: ["Keep your wrists straight.", "Don't let your elbows flare past 75°.", "Aim for a slight touch, not a bounce."],
                 videoURL: "", alternatives: ["incline-db-press", "cable-fly", "push-up"]),
        Exercise(id: "squat", name: "Squat",
                 primaryMuscles: [.quads, .glutes], secondaryMuscles: [.hamstrings, .core],
                 equipment: "barbell",
                 instructions: ["Bar across upper traps, feet shoulder-width.", "Brace your core and take a big breath.", "Push your knees out and sit down until hips are at or below parallel.", "Drive through your heels to stand.", "Keep your chest tall throughout."],
                 tips: ["Record from the side to check depth.", "Shoes with a slight heel raise help ankle mobility."],
                 videoURL: "", alternatives: ["leg-press", "hack-squat", "goblet-squat"]),
        Exercise(id: "deadlift", name: "Deadlift",
                 primaryMuscles: [.hamstrings, .glutes], secondaryMuscles: [.back, .traps, .forearms],
                 equipment: "barbell",
                 instructions: ["Bar over mid-foot, hip-width stance.", "Hinge and grip just outside your legs.", "Brace hard, chest up, pull the slack out of the bar.", "Push the floor away — don't jerk.", "Lock hips and shoulders out simultaneously at the top."],
                 tips: ["Don't round your lower back.", "Chalk or straps help grip on heavy sets."],
                 videoURL: "", alternatives: ["romanian-deadlift", "trap-bar-deadlift"]),
        Exercise(id: "pull-up", name: "Pull-Ups",
                 primaryMuscles: [.lats, .back], secondaryMuscles: [.biceps, .core],
                 equipment: "bodyweight",
                 instructions: ["Hang with arms fully extended, pronated grip.", "Initiate with your lats — think elbows to hips.", "Pull until your chin clears the bar.", "Lower slowly (3 seconds) for maximum stimulus.", "Re-extend fully between reps."],
                 tips: ["Add weight with a belt when bodyweight becomes easy.", "Band assistance is better than jumping."],
                 videoURL: "", alternatives: ["lat-pulldown", "assisted-pull-up"]),
        Exercise(id: "overhead-press", name: "Overhead Press",
                 primaryMuscles: [.shoulders], secondaryMuscles: [.triceps, .traps, .core],
                 equipment: "barbell",
                 instructions: ["Bar in front-rack position at collarbone, grip just outside shoulder-width.", "Brace core, slightly lean back, press the bar straight up.", "Move your head back then forward to let the bar path be vertical.", "Lock out overhead with biceps by ears.", "Lower under control to collarbone."],
                 tips: ["Squeeze your glutes to protect your lower back.", "Don't press behind the neck."],
                 videoURL: "", alternatives: ["db-shoulder-press", "arnold-press"]),
        Exercise(id: "incline-db-press", name: "Incline DB Press",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .triceps],
                 equipment: "dumbbell",
                 instructions: ["Set bench to 30–45°.", "Hold dumbbells at shoulder level, palms facing feet.", "Press up and slightly together without touching the heads.", "Lower with elbows ~75° from torso."],
                 tips: ["Incline targets the upper chest — don't go too steep or it becomes a shoulder press."],
                 videoURL: "", alternatives: ["bench-press", "cable-fly"]),
    ]

    static func find(_ id: String) -> Exercise? { library.first { $0.id == id } }
    static func alternatives(for ex: Exercise) -> [Exercise] { ex.alternatives.compactMap { find($0) } }
}

// MARK: - Detail View

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showSwap = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: equipmentIcon)
                                .font(.system(size: 12))
                            Text(exercise.equipment.capitalized)
                                .font(.sans(12, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.75))
                        Text(exercise.name)
                            .font(.serifDisplay(34))
                            .foregroundStyle(.white)
                    }
                    .padding(Spacing.md)
                }
                .slideIn()

                // Muscle map
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("MUSCLES").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                        HStack(alignment: .top, spacing: Spacing.xl) {
                            MuscleMapView(
                                primary: exercise.primaryMuscles,
                                secondary: exercise.secondaryMuscles,
                                view: .front
                            )
                            MuscleMapView(
                                primary: exercise.primaryMuscles,
                                secondary: exercise.secondaryMuscles,
                                view: .back
                            )
                        }
                        .frame(maxWidth: .infinity)
                        muscleLegend
                    }
                }
                .slideIn(delay: 0.06)

                // Instructions
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("HOW TO").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Text("\(i + 1)")
                                    .font(.sans(12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.green500, in: Circle())
                                Text(step)
                                    .font(.sans(14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if i < exercise.instructions.count - 1 { Divider() }
                        }
                    }
                }
                .slideIn(delay: 0.10)

                // Tips
                if !exercise.tips.isEmpty {
                    BBCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("COACHING TIPS").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                            ForEach(Array(exercise.tips.enumerated()), id: \.offset) { i, tip in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#E8A13A"))
                                        .padding(.top, 2)
                                    Text(tip).font(.sans(14)).fixedSize(horizontal: false, vertical: true)
                                }
                                if i < exercise.tips.count - 1 { Divider() }
                            }
                        }
                    }
                    .slideIn(delay: 0.14)
                }

                // Swap alternatives
                if !exercise.alternatives.isEmpty {
                    let alts = Exercise.alternatives(for: exercise)
                    if !alts.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("SWAP WITH")
                                .font(.sans(11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .kerning(1.3)
                            ForEach(alts) { alt in
                                NavigationLink(destination: ExerciseDetailView(exercise: alt)) {
                                    HStack {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.green500)
                                        Text(alt.name)
                                            .font(.sans(15, weight: .medium))
                                        Spacer()
                                        Text(alt.primaryMuscles.map(\.displayName).joined(separator: ", "))
                                            .font(.sans(12))
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(Spacing.md)
                                    .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.md))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .slideIn(delay: 0.18)
                    }
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.bbBackground)
        .navigationTitle(exercise.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var equipmentIcon: String {
        switch exercise.equipment {
        case "barbell": return "scalemass.fill"
        case "dumbbell": return "dumbbell.fill"
        case "cable": return "cable.connector"
        case "bodyweight": return "figure.gymnastics"
        default: return "gearshape.fill"
        }
    }

    private var muscleLegend: some View {
        HStack(spacing: Spacing.lg) {
            HStack(spacing: 6) {
                Circle().fill(Color.green500).frame(width: 10, height: 10)
                Text("Primary").font(.sans(12)).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Circle().fill(Color.green500.opacity(0.3)).frame(width: 10, height: 10)
                Text("Secondary").font(.sans(12)).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Anatomical muscle map (SVG-style SwiftUI paths)

enum BodyView { case front, back }

struct MuscleMapView: View {
    let primary: [Exercise.Muscle]
    let secondary: [Exercise.Muscle]
    let view: BodyView

    var body: some View {
        ZStack {
            // Body silhouette
            BodySilhouette(view: view)
                .fill(Color.secondary.opacity(0.08))
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)

            // Muscle highlights
            ForEach(Exercise.Muscle.allCases, id: \.self) { muscle in
                if muscleFits(muscle) {
                    MuscleShape(muscle: muscle, view: view)
                        .fill(color(for: muscle))
                }
            }
        }
        .frame(width: 90, height: 160)
        .overlay(alignment: .bottom) {
            Text(view == .front ? "Front" : "Back")
                .font(.sans(9))
                .foregroundStyle(.secondary)
                .padding(.bottom, -14)
        }
    }

    private func muscleFits(_ muscle: Exercise.Muscle) -> Bool {
        let frontMuscles: [Exercise.Muscle] = [.chest, .shoulders, .biceps, .core, .quads, .forearms]
        let backMuscles: [Exercise.Muscle] = [.back, .lats, .traps, .hamstrings, .glutes, .calves, .triceps]
        let muscles = view == .front ? frontMuscles : backMuscles
        return muscles.contains(muscle)
    }

    private func color(for muscle: Exercise.Muscle) -> Color {
        if primary.contains(muscle) { return Color.green500.opacity(0.7) }
        if secondary.contains(muscle) { return Color.green500.opacity(0.25) }
        return .clear
    }
}

// MARK: - Simple body silhouette path

struct BodySilhouette: Shape {
    let view: BodyView

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // Head
        p.addEllipse(in: CGRect(x: w * 0.3, y: 0, width: w * 0.4, height: h * 0.13))
        // Neck
        p.addRect(CGRect(x: w * 0.4, y: h * 0.12, width: w * 0.2, height: h * 0.05))
        // Torso
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.17))
        p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.17))
        p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.47))
        p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.47))
        p.closeSubpath()
        // Hips
        p.addRect(CGRect(x: w * 0.22, y: h * 0.46, width: w * 0.56, height: h * 0.08))
        // Left arm
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.17))
        p.addLine(to: CGPoint(x: 0, y: h * 0.22))
        p.addLine(to: CGPoint(x: 0, y: h * 0.48))
        p.addLine(to: CGPoint(x: w * 0.14, y: h * 0.48))
        p.closeSubpath()
        // Right arm
        p.move(to: CGPoint(x: w * 0.85, y: h * 0.17))
        p.addLine(to: CGPoint(x: w, y: h * 0.22))
        p.addLine(to: CGPoint(x: w, y: h * 0.48))
        p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.48))
        p.closeSubpath()
        // Left leg
        p.addRect(CGRect(x: w * 0.22, y: h * 0.54, width: w * 0.24, height: h * 0.46))
        // Right leg
        p.addRect(CGRect(x: w * 0.54, y: h * 0.54, width: w * 0.24, height: h * 0.46))
        return p
    }
}

// MARK: - Approximate muscle region shapes

struct MuscleShape: Shape {
    let muscle: Exercise.Muscle
    let view: BodyView

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        switch (muscle, view) {
        case (.chest, .front):
            p.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.18, width: w*0.64, height: h*0.14), cornerSize: CGSize(width: 6, height: 6))
        case (.shoulders, .front):
            p.addEllipse(in: CGRect(x: 0, y: h*0.17, width: w*0.18, height: h*0.1))
            p.addEllipse(in: CGRect(x: w*0.82, y: h*0.17, width: w*0.18, height: h*0.1))
        case (.biceps, .front):
            p.addRoundedRect(in: CGRect(x: 0, y: h*0.27, width: w*0.14, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
            p.addRoundedRect(in: CGRect(x: w*0.86, y: h*0.27, width: w*0.14, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
        case (.forearms, .front):
            p.addRoundedRect(in: CGRect(x: 0, y: h*0.39, width: w*0.14, height: h*0.09), cornerSize: CGSize(width: 3, height: 3))
            p.addRoundedRect(in: CGRect(x: w*0.86, y: h*0.39, width: w*0.14, height: h*0.09), cornerSize: CGSize(width: 3, height: 3))
        case (.core, .front):
            p.addRoundedRect(in: CGRect(x: w*0.28, y: h*0.32, width: w*0.44, height: h*0.15), cornerSize: CGSize(width: 5, height: 5))
        case (.quads, .front):
            p.addRoundedRect(in: CGRect(x: w*0.23, y: h*0.54, width: w*0.22, height: h*0.24), cornerSize: CGSize(width: 5, height: 5))
            p.addRoundedRect(in: CGRect(x: w*0.55, y: h*0.54, width: w*0.22, height: h*0.24), cornerSize: CGSize(width: 5, height: 5))
        case (.calves, .front):
            p.addRoundedRect(in: CGRect(x: w*0.24, y: h*0.79, width: w*0.20, height: h*0.16), cornerSize: CGSize(width: 4, height: 4))
            p.addRoundedRect(in: CGRect(x: w*0.56, y: h*0.79, width: w*0.20, height: h*0.16), cornerSize: CGSize(width: 4, height: 4))
        case (.back, .back):
            p.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.18, width: w*0.64, height: h*0.12), cornerSize: CGSize(width: 6, height: 6))
        case (.lats, .back):
            p.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.25, width: w*0.22, height: h*0.18), cornerSize: CGSize(width: 5, height: 5))
            p.addRoundedRect(in: CGRect(x: w*0.60, y: h*0.25, width: w*0.22, height: h*0.18), cornerSize: CGSize(width: 5, height: 5))
        case (.traps, .back):
            p.addRoundedRect(in: CGRect(x: w*0.25, y: h*0.14, width: w*0.50, height: h*0.10), cornerSize: CGSize(width: 5, height: 5))
        case (.triceps, .back):
            p.addRoundedRect(in: CGRect(x: 0, y: h*0.27, width: w*0.14, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
            p.addRoundedRect(in: CGRect(x: w*0.86, y: h*0.27, width: w*0.14, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
        case (.hamstrings, .back):
            p.addRoundedRect(in: CGRect(x: w*0.23, y: h*0.54, width: w*0.22, height: h*0.22), cornerSize: CGSize(width: 5, height: 5))
            p.addRoundedRect(in: CGRect(x: w*0.55, y: h*0.54, width: w*0.22, height: h*0.22), cornerSize: CGSize(width: 5, height: 5))
        case (.glutes, .back):
            p.addRoundedRect(in: CGRect(x: w*0.22, y: h*0.46, width: w*0.26, height: h*0.12), cornerSize: CGSize(width: 5, height: 5))
            p.addRoundedRect(in: CGRect(x: w*0.52, y: h*0.46, width: w*0.26, height: h*0.12), cornerSize: CGSize(width: 5, height: 5))
        case (.calves, .back):
            p.addRoundedRect(in: CGRect(x: w*0.24, y: h*0.79, width: w*0.20, height: h*0.16), cornerSize: CGSize(width: 4, height: 4))
            p.addRoundedRect(in: CGRect(x: w*0.56, y: h*0.79, width: w*0.20, height: h*0.16), cornerSize: CGSize(width: 4, height: 4))
        case (.shoulders, .back):
            p.addEllipse(in: CGRect(x: 0, y: h*0.17, width: w*0.18, height: h*0.1))
            p.addEllipse(in: CGRect(x: w*0.82, y: h*0.17, width: w*0.18, height: h*0.1))
        default:
            break
        }
        return p
    }
}
