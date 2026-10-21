import Foundation

/// Demo entries for one calendar day, newest first.
struct DayGroup: Equatable, Identifiable, Sendable {
    /// The day in `yyyy-MM-dd`, already resolved in the dataset's time zone.
    let day: String
    let entries: [DemoEntry]

    var id: String { day }
}

/// Groups entries into day buckets.
///
/// Provisional: step 05 implements the real history list, its cursor pagination and its
/// filters. Day bucketing is kept as a pure function so the boundary rules can be unit
/// tested offline (plan test 05-06, and 01-04 for the shell).
enum EntryGrouping {
    /// Groups by day using `timeZone`, ordered newest day first and newest entry first
    /// inside each day. An entry belongs to exactly one day.
    static func byDay(_ entries: [DemoEntry], timeZone: TimeZone) -> [DayGroup] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        var order: [String] = []
        var buckets: [String: [DemoEntry]] = [:]

        for entry in entries.sorted(by: { $0.occurredAt > $1.occurredAt }) {
            let day = formatter.string(from: entry.occurredAt)
            if buckets[day] == nil {
                order.append(day)
            }
            buckets[day, default: []].append(entry)
        }

        return order.map { DayGroup(day: $0, entries: buckets[$0] ?? []) }
    }
}
