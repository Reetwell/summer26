import Foundation
#if os(iOS)
import EventKit
#endif

// Mirrors web's sbp-mealshop + sbp-shop
struct ShopItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var amount: String
    var category: String    // "Protein" | "Carbs" | "Produce" | "Supplements" | "Other"
    var done: Bool = false
}

@Observable
final class ShoppingStore {
    static let shared = ShoppingStore()
    private let key = "sbp-mealshop"

    private(set) var items: [ShopItem] = []

    var sections: [(title: String, items: [ShopItem])] {
        let order = ["Protein", "Carbs", "Produce", "Supplements", "Other"]
        return order.compactMap { cat in
            let filtered = items.filter { $0.category == cat }
            return filtered.isEmpty ? nil : (title: cat, items: filtered)
        }
    }

    var totalCount: Int { items.count }
    var doneCount: Int { items.filter(\.done).count }

    private init() { load() }

    // MARK: - CRUD

    func toggle(id: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].done.toggle()
        persist()
    }

    func add(_ item: ShopItem) {
        items.append(item)
        persist()
    }

    func remove(id: String) {
        items.removeAll { $0.id == id }
        persist()
    }

    func clearDone() {
        items.removeAll(\.done)
        persist()
    }

    // MARK: - Build from meal plan ingredients

    func buildFromMealPlan(ingredients: [String]) {
        // Parse "200g chicken breast" → name = "Chicken breast", amount = "200g"
        let new: [ShopItem] = ingredients.map { raw in
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            if parts.count == 2, let _ = parseAmount(String(parts[0])) {
                return ShopItem(name: String(parts[1]).capitalized, amount: String(parts[0]), category: categorise(raw))
            }
            return ShopItem(name: trimmed.capitalized, amount: "", category: categorise(raw))
        }
        items = new
        persist()
    }

    // MARK: - Copy

    func copyText() -> String {
        sections.map { section in
            let header = "— \(section.title) —"
            let lines = section.items.map { ($0.done ? "✓ " : "• ") + $0.name + ($0.amount.isEmpty ? "" : " (\($0.amount))") }
            return ([header] + lines).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    // MARK: - Send to Reminders (iOS)

    #if os(iOS)
    func sendToReminders() async -> Bool {
        let store = EKEventStore()
        guard (try? await store.requestFullAccessToReminders()) == true else { return false }
        let list = store.defaultCalendarForNewReminders()
        for item in items where !item.done {
            let reminder = EKReminder(eventStore: store)
            reminder.title = "\(item.name)\(item.amount.isEmpty ? "" : " – \(item.amount)")"
            reminder.calendar = list
            try? store.save(reminder, commit: false)
        }
        try? store.commit()
        return true
    }
    #endif

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ShopItem].self, from: data) {
            items = decoded
        } else {
            items = Self.sampleItems
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Helpers

    private func parseAmount(_ s: String) -> Double? {
        Double(s.filter { $0.isNumber || $0 == "." })
    }

    private func categorise(_ text: String) -> String {
        let t = text.lowercased()
        if t.contains("chicken") || t.contains("beef") || t.contains("salmon") || t.contains("egg") || t.contains("yogurt") || t.contains("protein") || t.contains("tuna") { return "Protein" }
        if t.contains("rice") || t.contains("oat") || t.contains("wrap") || t.contains("bread") || t.contains("pasta") || t.contains("potato") || t.contains("banana") { return "Carbs" }
        if t.contains("broccoli") || t.contains("spinach") || t.contains("pepper") || t.contains("avocado") || t.contains("tomato") || t.contains("onion") { return "Produce" }
        if t.contains("creatine") || t.contains("whey") || t.contains("vitamin") || t.contains("supplement") { return "Supplements" }
        return "Other"
    }

    static let sampleItems: [ShopItem] = [
        ShopItem(name: "Chicken breast", amount: "1.2 kg", category: "Protein"),
        ShopItem(name: "Salmon fillets", amount: "4",      category: "Protein"),
        ShopItem(name: "Greek yogurt",   amount: "1 kg",   category: "Protein"),
        ShopItem(name: "Eggs",           amount: "12",     category: "Protein"),
        ShopItem(name: "Basmati rice",   amount: "1 kg",   category: "Carbs"),
        ShopItem(name: "Oats",           amount: "500 g",  category: "Carbs"),
        ShopItem(name: "Bananas",        amount: "6",      category: "Carbs"),
        ShopItem(name: "Broccoli",       amount: "2 heads",category: "Produce"),
        ShopItem(name: "Spinach",        amount: "400 g",  category: "Produce"),
        ShopItem(name: "Avocados",       amount: "2",      category: "Produce"),
        ShopItem(name: "Creatine monohydrate", amount: "500 g", category: "Supplements")
    ]
}

private extension Array {
    mutating func removeAll(_ predicate: KeyPath<Element, Bool>) {
        removeAll { $0[keyPath: predicate] }
    }
}
