import SwiftUI

// Recipe library — embedded in the Meals tab as a NavigationLink section
struct RecipesView: View {
    private let store = RecipeStore.shared
    @State private var showExtract = false
    @State private var searchText = ""

    private var filtered: [Recipe] {
        guard !searchText.isEmpty else { return store.recipes }
        return store.recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - iOS

    private var iosLayout: some View {
        List {
            Section {
                addRecipeRow
            }
            if store.recipes.isEmpty {
                Section {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } else {
                Section("YOUR RECIPES") {
                    ForEach(filtered) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            recipeRow(recipe)
                        }
                    }
                    .onDelete { idxs in
                        idxs.map { filtered[$0] }.forEach { store.delete($0) }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.bbBackground)
        .searchable(text: $searchText, prompt: "Search recipes")
        .navigationTitle("Recipes")
        .sheet(isPresented: $showExtract) { RecipeExtractView() }
    }

    // MARK: - macOS

    private var macLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Recipes")
                    .font(.serifDisplay(34))
                Spacer()
                Button {
                    showExtract = true
                } label: {
                    Label("Add recipe", systemImage: "plus")
                        .font(.sans(14, weight: .semibold))
                        .foregroundStyle(Color.green500)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.green500.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if store.recipes.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filtered) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            macRecipeCard(recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showExtract) { RecipeExtractView() }
    }

    // MARK: - Subviews

    private var addRecipeRow: some View {
        Button {
            showExtract = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.green500)
                    .frame(width: 40, height: 40)
                    .background(Color.green500.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Paste a TikTok / IG / YouTube link")
                        .font(.sans(15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("AI extracts the recipe in seconds")
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green500.opacity(0.1))
                Image(systemName: platformIcon(recipe.platform))
                    .font(.system(size: 18))
                    .foregroundStyle(Color.green500)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(.sans(15, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(recipe.macros.kcal) kcal")
                        .font(.sans(12))
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(recipe.macros.p)g protein")
                        .font(.sans(12, weight: .semibold))
                        .foregroundStyle(Color.green500)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func macRecipeCard(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: platformIcon(recipe.platform))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.green500)
                Spacer()
                Text(recipe.platform.capitalized)
                    .font(.sans(10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .kerning(0.8)
            }
            Text(recipe.title)
                .font(.serifDisplay(18))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if !recipe.author.isEmpty {
                Text(recipe.author)
                    .font(.sans(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: Spacing.md) {
                macroChip("\(recipe.macros.kcal)", "kcal")
                macroChip("\(recipe.macros.p)g", "protein")
            }
        }
        .padding(Spacing.md)
        .frame(height: 160, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }

    private func macroChip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.sans(13, weight: .bold)).foregroundStyle(Color.green500)
            Text(label).font(.sans(9)).foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.green500.opacity(0.4))
            Text("No recipes yet")
                .font(.serifDisplay(22))
            Text("Paste a TikTok, Instagram or YouTube link and we'll extract the recipe with AI.")
                .font(.sans(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showExtract = true
            } label: {
                Label("Add your first recipe", systemImage: "plus")
                    .font(.sans(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green500, in: Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private func platformIcon(_ platform: String) -> String {
        switch platform {
        case "tiktok": return "play.rectangle.fill"
        case "instagram": return "camera.fill"
        case "youtube": return "play.circle.fill"
        default: return "link"
        }
    }
}
