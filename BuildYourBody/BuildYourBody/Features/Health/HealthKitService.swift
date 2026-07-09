#if os(iOS)
import HealthKit

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var authorized = false
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // Latest fetched values (nil = not yet fetched / no data)
    var sleepHours: Double?    // total sleep last night
    var restingHR: Double?     // bpm
    var hrv: Double?           // SDNN ms
    var steps: Int?            // today

    private init() {}

    func requestAuthorization() async {
        guard isAvailable else { return }
        let read: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: read)
            authorized = true
            await fetchAll()
        } catch {
            authorized = false
        }
    }

    func fetchAll() async {
        async let s = fetchSleepHours()
        async let r = fetchRestingHR()
        async let h = fetchHRV()
        async let st = fetchSteps()
        let (sleep, rhr, hrvVal, stepVal) = await (s, r, h, st)
        sleepHours = sleep
        restingHR = rhr
        hrv = hrvVal
        steps = stepVal
    }

    // MARK: - Sleep

    private func fetchSleepHours() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -16, to: now) ?? now
        let pred = HKQuery.predicateForSamples(withStart: start, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: pred, limit: 50, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else { continuation.resume(returning: nil); return }
                let asleepValues: Set<HKCategoryValueSleepAnalysis> = [.asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified]
                let totalSeconds = samples
                    .filter { asleepValues.contains(HKCategoryValueSleepAnalysis(rawValue: $0.value)!) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3600 : nil)
            }
            store.execute(query)
        }
    }

    // MARK: - Resting HR

    private func fetchRestingHR() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        return await fetchLatestQuantity(type, unit: .count().unitDivided(by: .minute()))
    }

    // MARK: - HRV

    private func fetchHRV() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        return await fetchLatestQuantity(type, unit: .secondUnit(with: .milli))
    }

    // MARK: - Steps

    private func fetchSteps() async -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: val.map { Int($0) })
            }
            store.execute(query)
        }
    }

    // MARK: - Helpers

    private func fetchLatestQuantity(_ type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else { continuation.resume(returning: nil); return }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep rating helper (1-5 from hours)

    func sleepRating() -> Int? {
        guard let h = sleepHours else { return nil }
        switch h {
        case ..<5:    return 1
        case 5..<6:   return 2
        case 6..<7:   return 3
        case 7..<8:   return 4
        default:      return 5
        }
    }
}
#endif
