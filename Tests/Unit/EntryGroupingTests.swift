import XCTest

@testable import LittleNest

/// Day bucketing is a pure function, so time-zone boundaries can be checked offline
/// (plan tests 01-04 and 05-06).
final class EntryGroupingTests: XCTestCase {
    private let entries = DemoFixtures.dataset(for: .f1).recentEntries

    private func timeZone(_ identifier: String) -> TimeZone {
        TimeZone(identifier: identifier)!
    }

    func testEveryEntryLandsInExactlyOneDay() {
        let groups = EntryGrouping.byDay(entries, timeZone: timeZone("Asia/Shanghai"))

        XCTAssertEqual(groups.reduce(0) { $0 + $1.entries.count }, entries.count)
        XCTAssertEqual(Set(groups.map(\.day)).count, groups.count, "days must not repeat")
    }

    func testDaysAreNewestFirst() {
        let days = EntryGrouping.byDay(entries, timeZone: timeZone("Asia/Shanghai")).map(\.day)

        XCTAssertEqual(days, days.sorted(by: >))
        XCTAssertEqual(days, ["2026-10-16", "2026-10-15", "2026-10-13", "2026-10-10"])
    }

    func testEntriesInsideADayAreNewestFirst() {
        for group in EntryGrouping.byDay(entries, timeZone: timeZone("Asia/Shanghai")) {
            let instants = group.entries.map(\.occurredAt)
            XCTAssertEqual(instants, instants.sorted(by: >), "day \(group.day)")
        }
    }

    func testShanghaiBucketsFiveLateEveningRecordsIntoTheNextDay() {
        let groups = EntryGrouping.byDay(entries, timeZone: timeZone("Asia/Shanghai"))
        let counts = Dictionary(uniqueKeysWithValues: groups.map { ($0.day, $0.entries.count) })

        // 22:00 local on the 15th and later all fall on the 16th in Asia/Shanghai.
        XCTAssertEqual(counts["2026-10-16"], 5)
        XCTAssertEqual(counts["2026-10-15"], 1)
    }

    func testUTCBucketsTheSameRecordsDifferently() {
        let groups = EntryGrouping.byDay(entries, timeZone: timeZone("UTC"))
        let counts = Dictionary(uniqueKeysWithValues: groups.map { ($0.day, $0.entries.count) })

        XCTAssertEqual(counts["2026-10-16"], 1)
        XCTAssertEqual(counts["2026-10-15"], 5)
    }

    func testEmptyInputProducesNoGroups() {
        XCTAssertTrue(EntryGrouping.byDay([], timeZone: timeZone("UTC")).isEmpty)
    }
}
