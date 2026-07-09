import SwiftUI

struct RecipeDetailView: View {
    @State private var recipe: Recipe
    @State private var editing = false
    @Environment(\.dismiss) private var dismiss
    private let store = RecipeStore.shared

    init(recipe: Recipe) {
        _recipe = State(initialValue: recipe)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Label(recipe.platform.capitalized, systemImage: platformIcon)
                            .font(.sans(11, weight: .bold))
                            .foregroundStyle(Color.green500)
                            .kerning(0.6)
                        Spacer()
                        Text(formattedDate)
                            .font(.sans(11))
                            .foregroundStyle(.secondary)
                    }
                    Text(recipe.title)
                        .font(.serifDisplay(34))
                    if !recipe.author.isEmpty {
                        Text(recipe.author)
                            .font(.sans(14))
                            .foregroundStyle(.secondary)
                    }
                }
                .slideIn()

                // Macro strip
                BBCard {
                    HStack {
                        macroPill("\(recipe.macros.kcal)", "kcal", Color(hex: "#E8A13A"))
                        Divider().frame(height: 36)
                        macroPill("\(recipe.macros.p)g", "protein", Color.green500)
                        Divider().frame(height: 36)
                        macroPill("\(recipe.macros.c)g", "carbs", Color(hex: "#4A90D9"))
                        Divider().frame(height: 36)
                        macroPill("\(recipe.macros.f)g", "fat", Color(hex: "#E05C5C"))
                    }
                }
                .slideIn(delay: 0.04)

                // Ingredients
                if !recipe.ingredients.isEmpty {
                    BBCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("INGREDIENTS")
                                .font(.sans(11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .kerning(1.3)
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, ing in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 5))
                                        .foregroundStyle(Color.green500)
                                        .padding(.top, 7)
                                    Text(ing)
                                        .font(.sans(14))
                                }
                                if i < recipe.ingredients.count - 1 { Divider() }
                            }
                        }
                    }
                    .slideIn(delay: 0.08)
                }

                // Steps
                if !recipe.steps.isEmpty {
                    BBCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("METHOD")
                                .font(.sans(11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .kerning(1.3)
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Text("\(i + 1)")
                                        .font(.sans(13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.green500, in: Circle())
                                    Text(step)
                                        .font(.sans(14))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 2)
                                if i < recipe.steps.count - 1 { Divider() }
                            }
                        }
                    }
                    .slideIn(delay: 0.12)
                }

                // Source link
                if let url = URL(string: recipe.canonicalUrl), !recipe.canonicalUrl.isEmpty {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: platformIcon)
                            Text("View original")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.sans(14, weight: .semibold))
                        .foregroundStyle(Color.green500)
                        .padding(Spacing.md)
                        .background(Color.green500.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .slideIn(delay: 0.16)
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.bbBackground)
        .navigationTitle(recipe.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit recipe") { editing = true }
                    Button("Delete recipe", role: .destructive) {
                        store.delete(recipe)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $editing) {
            NavigationStack {
                EditableRecipeForm(recipe: recipe) { saved in
                    recipe = saved
                    store.save(saved)
                    editing = false
                }
                .navigationTitle("Edit recipe")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editing = false }
                    }
                }
            }
        }
    }

    private var platformIcon: String {
        switch recipe.platform {
        case "tiktok": return "play.rectangle.fill"
        case "instagram": return "camera.fill"
        case "youtube": return "play.circle.fill"
        default: return "link"
        }
    }

    private var formattedDate: String {
        let d = Date(timeIntervalSince1970: recipe.ts)
        return d.formatted(.dateTime.day().month(.abbreviated))
    }

    private func macroPill(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.serifDisplay(20)).foregroundStyle(color)
            Text(label).font(.sans(10)).foregroundStyle(.secondary).kerning(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}
