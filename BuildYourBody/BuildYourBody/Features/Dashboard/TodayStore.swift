import Foundation
#if os(iOS)
import UserNotifications
#endif

// Mirrors web's sbp-today: { [ISO-date]: { water:Int, creatine:Bool, junk:String[] } }
struct TodayLog: Codable {
    var water: Double       // litres
    var creatine: Bool
    var junk: [String]      // free-text junk food entries
}

@Observable
final class TodayStore {
    static let shared = TodayStore()
    private let key = "sbp-today"
    private let remKey = "sbp-reminders"

    private var allLogs: [String: TodayLog] = [:]

    // Reminder times (mirrors web remState)
    var proteinReminderTime = "09:00"
    var creatineReminderTime = "20:00"
    var waterReminderTime = "12:00"
    var remindersEnabled = false

    private init() { load() }

    // MARK: - Today's log

    var todayLog: TodayLog {
        get { allLogs[todayKey()] ?? TodayLog(water: 0, creatine: false, junk: []) }
        set { allLogs[todayKey()] = newValue; persist() }
    }

    func addWater(_ amount: Double) {
        var log = todayLog
        log.water = min(log.water + amount, 6.0)
        todayLog = log
    }

    func toggleCreatine() {
        var log = todayLog
        log.creatine.toggle()
        todayLog = log
    }

    func logJunk(_ name: String) {
        var log = todayLog
        log.junk.append(name)
        todayLog = log
    }

    func removeJunk(at offsets: IndexSet) {
        var log = todayLog
        log.junk.remove(atOffsets: offsets)
        todayLog = log
    }

    // MARK: - Reminders

    #if os(iOS)
    func requestNotificationPermission() async {
        let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        remindersEnabled = granted ?? false
        if remindersEnabled { scheduleAll() }
    }

    func scheduleAll() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["bb-protein", "bb-creatine", "bb-water"])
        schedule(id: "bb-protein",   title: "Protein check",   body: "Hit your protein target today 💪", timeString: proteinReminderTime)
        schedule(id: "bb-creatine",  title: "Creatine time",   body: "Don't forget your creatine 🟢",  timeString: creatineReminderTime)
        schedule(id: "bb-water",     title: "Hydration check", body: "How's your water intake? 💧",    timeString: waterReminderTime)
    }

    private func schedule(id: String, title: String, body: String, timeString: String) {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return }
        var comps = DateComponents()
        comps.hour = parts[0]; comps.minute = parts[1]
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
    #endif

    // MARK: - Persistence

    private func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: TodayLog].self, from: data) {
            allLogs = decoded
        }
        if let data = UserDefaults.standard.data(forKey: remKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            proteinReminderTime  = dict["protein"]  ?? "09:00"
            creatineReminderTime = dict["creatine"] ?? "20:00"
            waterReminderTime    = dict["water"]    ?? "12:00"
        }
        remindersEnabled = UserDefaults.standard.bool(forKey: "bb-reminders-enabled")
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveReminders() {
        let dict = ["protein": proteinReminderTime, "creatine": creatineReminderTime, "water": waterReminderTime]
        if let data = try? JSONEncoder().encode(dict) { UserDefaults.standard.set(data, forKey: remKey) }
        UserDefaults.standard.set(remindersEnabled, forKey: "bb-reminders-enabled")
        #if os(iOS)
        if remindersEnabled { scheduleAll() }
        #endif
    }
}
