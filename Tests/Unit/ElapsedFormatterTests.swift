import XCTest

@testable import LittleNest

/// Relative time labels must be deterministic and must never render a negative duration.
final class ElapsedFormatterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_792_112_400)

    private func label(secondsAgo: TimeInterval) -> String {
        ElapsedFormatter.shortLabel(from: now.addingTimeInterval(-secondsAgo), to: now)
    }

    func testUnderAMinuteIsJustNow() {
        XCTAssertEqual(label(secondsAgo: 0), "刚刚")
        XCTAssertEqual(label(secondsAgo: 59), "刚刚")
    }

    func testMinutes() {
        XCTAssertEqual(label(secondsAgo: 60), "1 分钟前")
        XCTAssertEqual(label(secondsAgo: 5 * 60), "5 分钟前")
        XCTAssertEqual(label(secondsAgo: 59 * 60), "59 分钟前")
    }

    func testHours() {
        XCTAssertEqual(label(secondsAgo: 60 * 60), "1 小时前")
        XCTAssertEqual(label(secondsAgo: 3 * 60 * 60), "3 小时前")
        XCTAssertEqual(label(secondsAgo: 23 * 60 * 60 + 59 * 60), "23 小时前")
    }

    func testDays() {
        XCTAssertEqual(label(secondsAgo: 24 * 60 * 60), "1 天前")
        XCTAssertEqual(label(secondsAgo: 2 * 24 * 60 * 60 + 3600), "2 天前")
    }

    func testFutureInstantsClampInsteadOfGoingNegative() {
        XCTAssertEqual(ElapsedFormatter.shortLabel(from: now.addingTimeInterval(120), to: now), "刚刚")
    }

    func testDayCount() {
        let birth = now.addingTimeInterval(-179 * 86_400)

        XCTAssertEqual(ElapsedFormatter.dayCount(from: birth, to: now), 179)
        XCTAssertEqual(ElapsedFormatter.dayCountLabel(from: birth, to: now), "179 天")
        XCTAssertEqual(ElapsedFormatter.dayCount(from: now.addingTimeInterval(86_400), to: now), 0)
    }
}
