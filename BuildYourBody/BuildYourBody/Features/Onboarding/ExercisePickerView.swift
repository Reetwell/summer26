import SwiftUI

// Searchable full-library exercise picker — add/remove exercises for one day
struct ExercisePickerView: View {
    @Binding var day: OnbPlanDay
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filteredLibrary: [(muscle: String, exercises: [String])] {
        guard !search.isEmpty else { return PlanBuilder.library }
        return PlanBuilder.library.compactMap { group in
            let matches = group.exercises.filter { $0.localizedCaseInsensitiveContains(search) }
            return matches.isEmpty ? nil : (group.muscle, matches)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(filteredLibrary, id: \.muscle) { group in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(group.muscle.uppercased())
                                .font(.sans(11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .kerning(1.2)

                            BBCard(padding: Spacing.xs) {
                                VStack(spacing: 0) {
                                    ForEach(group.exercises, id: \.self) { name in
                                        exerciseRow(name: name, muscle: group.muscle)
                                        if name != group.exercises.last {
                                            Divider().padding(.leading, Spacing.md)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.bbBackground)
            .navigationTitle("Add exercises")
            .inlineNavigationTitle()
            .searchable(text: $search, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.sans(15, weight: .semibold))
                        .foregroundStyle(Color.green500)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 600)
        #endif
    }

    private func exerciseRow(name: String, muscle: String) -> some View {
        let included = day.exercises.contains { $0.name == name }

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                if included {
                    day.exercises.removeAll { $0.name == name }
                } else {
                    day.exercises.append(OnbExercise(name: name, muscle: muscle))
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(name)
                    .font(.sans(14, weight: included ? .medium : .regular))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: included ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(included ? Color.green500 : Color.secondary.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
