import Foundation

// Mirrors web's sbp-readiness: { [ISO-date]: ReadinessEntry }
struct ReadinessEntry: Codable {
    var sleep: Int       // 1-5
    var energy: Int      // 1-5
    var soreness: Int    // 1-5
    var score: Int       // 0-100
    var source: String   // "manual" | "healthkit"
}

@Observable
final class ReadinessStore {
    static let shared = ReadinessStore()
    private let key = "sbp-readiness"
    private var entries: [String: ReadinessEntry] = [:]

    private init() { load() }

    private static var isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func todayKey() -> String {
        ReadinessStore.isoFormatter.string(from: Date())
    }

    var todayEntry: ReadinessEntry? { entries[todayKey()] }

    var todayScore: Int? { todayEntry?.score }

    var scoreLabel: String {
        guard let s = todayScore else { return "No data" }
        switch s {
        case 80...: return "Recovered"
        case 60..<80: return "Moderate"
        default: return "Take it easy"
        }
    }

    var scoreHint: String {
        guard let s = todayScore else { return "How are you feeling today?" }
        switch s {
        case 80...: return "Good day to push hard."
        case 60..<80: return "Solid session — listen to your body."
        default: return "Dial back intensity today."
        }
    }

    func save(sleep: Int, energy: Int, soreness: Int, source: String = "manual") {
        let score = Int(Double(sleep + energy + (6 - soreness)) / 15.0 * 100)
        let entry = ReadinessEntry(sleep: sleep, energy: energy, soreness: soreness, score: score, source: source)
        entries[todayKey()] = entry
        persist()
    }

    // Returns last 7 days of entries for charts
    func last7Days() -> [(date: String, score: Int)] {
        (0..<7).compactMap { offset in
            guard let d = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let k = ReadinessStore.isoFormatter.string(from: d)
            guard let e = entries[k] else { return nil }
            return (date: k, score: e.score)
        }.reversed()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ReadinessEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
