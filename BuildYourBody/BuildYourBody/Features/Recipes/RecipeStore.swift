import Foundation

struct Recipe: Identifiable, Codable {
    var id: String
    var url: String
    var canonicalUrl: String
    var platform: String      // "tiktok" | "instagram" | "youtube" | "other"
    var embedId: String
    var title: String
    var author: String
    var thumbnail: String
    var ingredients: [String]
    var steps: [String]
    var macros: Macros
    var ts: TimeInterval      // Date.timeIntervalSince1970

    struct Macros: Codable {
        var p: Int    // protein g
        var c: Int    // carbs g
        var f: Int    // fat g
        var kcal: Int
    }
}

// Mirror of web's Worker response shape from POST /recipe/extract
struct RecipeExtractResponse: Codable {
    var id: String?
    var url: String?
    var canonicalUrl: String?
    var platform: String?
    var embedId: String?
    var title: String?
    var author: String?
    var thumbnail: String?
    var ingredients: [String]?
    var steps: [String]?
    var macros: Recipe.Macros?
    var ts: TimeInterval?
    var error: String?
}

@Observable
final class RecipeStore {
    static let shared = RecipeStore()
    private let key = "sbp-recipes"
    private let workerBase = "https://summerbody.me-e29.workers.dev"

    private(set) var recipes: [Recipe] = []
    var isExtracting = false
    var extractError: String?

    private init() { load() }

    // MARK: - Extract from URL

    func extract(urlString: String) async -> Recipe? {
        guard let url = URL(string: "\(workerBase)/recipe/extract") else { return nil }
        isExtracting = true
        extractError = nil
        defer { isExtracting = false }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["url": urlString])

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let resp = try JSONDecoder().decode(RecipeExtractResponse.self, from: data)
            if let err = resp.error { extractError = err; return nil }
            let recipe = Recipe(
                id: resp.id ?? UUID().uuidString,
                url: resp.url ?? urlString,
                canonicalUrl: resp.canonicalUrl ?? urlString,
                platform: resp.platform ?? "other",
                embedId: resp.embedId ?? "",
                title: resp.title ?? "Untitled recipe",
                author: resp.author ?? "",
                thumbnail: resp.thumbnail ?? "",
                ingredients: resp.ingredients ?? [],
                steps: resp.steps ?? [],
                macros: resp.macros ?? Recipe.Macros(p: 0, c: 0, f: 0, kcal: 0),
                ts: resp.ts ?? Date().timeIntervalSince1970
            )
            return recipe
        } catch {
            extractError = "Could not extract recipe. Check the link and try again."
            return nil
        }
    }

    // MARK: - Library CRUD

    func save(_ recipe: Recipe) {
        if let i = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[i] = recipe
        } else {
            recipes.insert(recipe, at: 0)
        }
        persist()
    }

    func delete(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Recipe].self, from: data) else {
            recipes = []   // fresh install — no saved recipes yet
            return
        }
        recipes = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(recipes) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
