import SwiftUI

// Active session sheet — exercise list + mark-done button
struct SessionView: View {
    let session: TrainingPlan.Session
    let phase: TrainingPlan.Phase
    @Environment(\.dismiss) private var dismiss
    private let store = TrainingStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phase.badge.uppercased())
                            .font(.sans(11, weight: .bold))
                            .foregroundStyle(Color.green500)
                            .kerning(1.2)
                        Text(session.name)
                            .font(.serifDisplay(32))
                        HStack(spacing: Spacing.sm) {
                            Label("\(session.exercises.count) exercises", systemImage: "dumbbell.fill")
                            Text("·")
                            Text(session.duration)
                        }
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                    }
                    .slideIn()

                    // Exercise list with links to detail
                    BBCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("EXERCISES").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                                .padding(.bottom, Spacing.sm)
                            ForEach(Array(session.exercises.enumerated()), id: \.offset) { i, name in
                                let ex = Exercise.library.first { $0.name == name }
                                NavigationLink(destination: ex.map { ExerciseDetailView(exercise: $0) }) {
                                    HStack(spacing: Spacing.sm) {
                                        Text("\(i + 1)")
                                            .font(.sans(12, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 26, height: 26)
                                            .background(Color.green500, in: Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name)
                                                .font(.sans(15, weight: .medium))
                                                .foregroundStyle(.primary)
                                            if let ex {
                                                Text(ex.primaryMuscles.map(\.displayName).joined(separator: " · "))
                                                    .font(.sans(12))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if ex != nil {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(.vertical, Spacing.sm)
                                }
                                .disabled(ex == nil)
                                .buttonStyle(.plain)
                                if i < session.exercises.count - 1 { Divider() }
                            }
                        }
                    }
                    .slideIn(delay: 0.06)

                    // Mark done / undo
                    if store.isDone() {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.green500)
                            Text("Session logged for today")
                                .font(.sans(15, weight: .semibold))
                            Spacer()
                            Button("Undo") {
                                store.markUndone()
                            }
                            .font(.sans(13))
                            .foregroundStyle(.secondary)
                        }
                        .padding(Spacing.md)
                        .background(Color.green500.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.md))
                        .slideIn(delay: 0.10)
                    } else {
                        BBButton(title: "Mark session done") {
                            store.markDone()
                            dismiss()
                        }
                        .slideIn(delay: 0.10)
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.bbBackground)
            .navigationTitle(session.focus)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Plan Details view (all phases + sessions)

struct PlanDetailsView: View {
    private let store = TrainingStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.plan.name)
                        .font(.serifDisplay(28))
                    Text("\(store.plan.phases.count) phases · \(store.plan.phases.reduce(0) { $0 + $1.weeks }) weeks total")
                        .font(.sans(14))
                        .foregroundStyle(.secondary)
                }
                .slideIn()

                ForEach(Array(store.plan.phases.enumerated()), id: \.element.id) { i, phase in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phase.badge)
                                    .font(.serifDisplay(22))
                                Text("\(phase.weeks) weeks · \(phase.sessions.filter { $0.focus != "Rest" }.count) sessions/week")
                                    .font(.sans(13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.activePhaseIndex == i {
                                Text("ACTIVE")
                                    .font(.sans(10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green500, in: Capsule())
                                    .kerning(0.8)
                            } else {
                                Button("Activate") {
                                    store.activatePhase(i)
                                }
                                .font(.sans(13, weight: .semibold))
                                .foregroundStyle(Color.green500)
                            }
                        }

                        BBCard {
                            VStack(spacing: 0) {
                                ForEach(phase.sessions) { session in
                                    HStack(spacing: Spacing.sm) {
                                        Text(session.day)
                                            .font(.sans(12, weight: .bold))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 36, alignment: .leading)
                                        Circle()
                                            .fill(session.focus == "Rest" ? Color.secondary.opacity(0.2) : Color.green500)
                                            .frame(width: 8, height: 8)
                                        Text(session.focus == "Rest" ? "Rest" : "\(session.name)")
                                            .font(.sans(14, weight: session.focus == "Rest" ? .regular : .medium))
                                            .foregroundStyle(session.focus == "Rest" ? .secondary : .primary)
                                        Spacer()
                                        if !session.duration.isEmpty {
                                            Text(session.duration)
                                                .font(.sans(12))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    if session.id != phase.sessions.last?.id { Divider() }
                                }
                            }
                        }
                    }
                    .slideIn(delay: Double(i) * 0.06)
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.bbBackground)
        .navigationTitle("Plan Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
