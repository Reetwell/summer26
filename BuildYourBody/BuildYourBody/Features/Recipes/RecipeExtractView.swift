import SwiftUI

struct RecipeExtractView: View {
    @Environment(\.dismiss) private var dismiss
    private let store = RecipeStore.shared

    @State private var urlText = ""
    @State private var draft: Recipe?
    @State private var phase: Phase = .input

    enum Phase { case input, loading, editing, done }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .input:   inputView
                case .loading: loadingView
                case .editing: if let d = draft { editingView(d) } else { inputView }
                case .done:    EmptyView()
                }
            }
            .background(Color.bbBackground)
            .navigationTitle("Add recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.sans(15))
                }
            }
        }
    }

    // MARK: - Input

    private var inputView: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Paste a link")
                    .font(.serifDisplay(32))
                Text("TikTok, Instagram, or YouTube recipe video → AI-drafted recipe in seconds.")
                    .font(.sans(14))
                    .foregroundStyle(.secondary)
            }
            .slideIn()

            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "link")
                        .foregroundStyle(Color.green500)
                    TextField("https://www.tiktok.com/...", text: $urlText)
                        .font(.sans(15))
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        #endif
                }
                .padding(Spacing.md)
                .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.md))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.green500.opacity(urlText.isEmpty ? 0 : 0.4), lineWidth: 1.5))

                BBButton(title: "Extract recipe") {
                    Task { await extract() }
                }
                .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .slideIn(delay: 0.06)

            // Platform chips
            HStack(spacing: Spacing.sm) {
                ForEach(["TikTok", "Instagram", "YouTube"], id: \.self) { p in
                    Label(p, systemImage: platformIcon(p))
                        .font(.sans(12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.bbSurface, in: Capsule())
                }
            }
            .slideIn(delay: 0.1)

            Spacer()
        }
        .padding(Spacing.md)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color.green500)
            Text("Extracting recipe…")
                .font(.sans(15))
                .foregroundStyle(.secondary)
            Text(urlText)
                .font(.sans(12))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
    }

    // MARK: - Editing (review + tweak before saving)

    private func editingView(_ recipe: Recipe) -> some View {
        EditableRecipeForm(recipe: recipe) { saved in
            store.save(saved)
            phase = .done
            dismiss()
        }
    }

    // MARK: - Extract

    private func extract() async {
        let trimmed = urlText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        phase = .loading
        if let result = await store.extract(urlString: trimmed) {
            draft = result
            phase = .editing
        } else {
            phase = .input
        }
    }

    private func platformIcon(_ p: String) -> String {
        switch p { case "TikTok": return "play.rectangle.fill"; case "Instagram": return "camera.fill"; default: return "play.circle.fill" }
    }
}

// MARK: - Editable form (used for review after extract and for editing existing recipes)

struct EditableRecipeForm: View {
    @State private var recipe: Recipe
    let onSave: (Recipe) -> Void

    init(recipe: Recipe, onSave: @escaping (Recipe) -> Void) {
        _recipe = State(initialValue: recipe)
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Title + author
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("RECIPE DETAILS").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                        TextField("Title", text: $recipe.title)
                            .font(.serifDisplay(22))
                        TextField("Author / source", text: $recipe.author)
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                }
                .slideIn()

                // Macros
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("MACROS").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                        HStack(spacing: Spacing.md) {
                            macroField("Kcal", value: Binding(get: { recipe.macros.kcal }, set: { recipe.macros.kcal = $0 }), color: Color(hex: "#E8A13A"))
                            macroField("Protein", value: Binding(get: { recipe.macros.p }, set: { recipe.macros.p = $0 }), color: Color.green500)
                            macroField("Carbs",   value: Binding(get: { recipe.macros.c }, set: { recipe.macros.c = $0 }), color: Color(hex: "#4A90D9"))
                            macroField("Fat",     value: Binding(get: { recipe.macros.f }, set: { recipe.macros.f = $0 }), color: Color(hex: "#E05C5C"))
                        }
                    }
                }
                .slideIn(delay: 0.04)

                // Ingredients
                editableList(title: "INGREDIENTS", items: $recipe.ingredients, placeholder: "Add ingredient…")
                    .slideIn(delay: 0.08)

                // Steps
                editableList(title: "STEPS", items: $recipe.steps, placeholder: "Add step…", numbered: true)
                    .slideIn(delay: 0.12)

                BBButton(title: "Save recipe") { onSave(recipe) }
                    .slideIn(delay: 0.16)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.bbBackground)
    }

    private func macroField(_ label: String, value: Binding<Int>, color: Color) -> some View {
        VStack(spacing: 3) {
            TextField("0", value: value, format: .number)
                .font(.serifDisplay(22))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .frame(maxWidth: .infinity)
            Text(label).font(.sans(10)).foregroundStyle(.secondary).kerning(0.8)
        }
    }

    private func editableList(title: String, items: Binding<[String]>, placeholder: String, numbered: Bool = false) -> some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title).font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.3)
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        if numbered {
                            Text("\(i + 1).")
                                .font(.sans(14, weight: .semibold))
                                .foregroundStyle(Color.green500)
                                .frame(width: 22, alignment: .trailing)
                        } else {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(Color.green500)
                                .padding(.top, 7)
                        }
                        TextField(placeholder, text: items[i], axis: .vertical)
                            .font(.sans(14))
                    }
                    .padding(.vertical, 2)
                    if i < items.wrappedValue.count - 1 { Divider() }
                }
                Button {
                    items.wrappedValue.append("")
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.sans(13, weight: .semibold))
                        .foregroundStyle(Color.green500)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }
}
