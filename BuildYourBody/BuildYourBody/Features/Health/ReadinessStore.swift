import Foundation
import Supabase

// Mirrors web's sbp-readiness: { [ISO-date]: ReadinessEntry }
struct ReadinessEntry: Codable {
    var sleep: Int       // 1-5
    var energy: Int      // 1-5
    var soreness: Int    // 1-5
    var score: Int       // 0-100
    var source: String   // "manual" | "healthkit"
}

// Row shape matching Supabase app_data table
private struct AppDataUpsert: Encodable {
    let user_id: String
    let key: String
    let value: [String: ReadinessEntry]
}

private struct AppDataRow: Decodable {
    let value: [String: ReadinessEntry]
}

@Observable
final class ReadinessStore {
    static let shared = ReadinessStore()
    private let udKey = "sbp-readiness"
    private var entries: [String: ReadinessEntry] = [:]

    private let supabase = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseAnonKey
    )

    private init() {
        load()
        Task { await loadFromSupabase() }
    }

    private static let isoFormatter: DateFormatter = {
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
        Task { await syncToSupabase() }
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

    // MARK: - Supabase sync

    private func currentUserId() async -> String? {
        guard let session = try? await supabase.auth.session else { return nil }
        return session.user.id.uuidString
    }

    private func syncToSupabase() async {
        guard let uid = await currentUserId() else { return }
        let row = AppDataUpsert(user_id: uid, key: "bb-readiness-native", value: entries)
        _ = try? await supabase.from("app_data")
            .upsert(row, onConflict: "user_id,key")
            .execute()
    }

    private func loadFromSupabase() async {
        guard let uid = await currentUserId() else { return }
        guard let rows = try? await supabase.from("app_data")
            .select("value")
            .eq("user_id", value: uid)
            .eq("key", value: "bb-readiness-native")
            .execute()
            .value as [AppDataRow],
              let remote = rows.first else { return }
        // Merge: remote fills dates we don't have locally; local wins on conflict
        for (date, entry) in remote.value where entries[date] == nil {
            entries[date] = entry
        }
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: ReadinessEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
    }
}
