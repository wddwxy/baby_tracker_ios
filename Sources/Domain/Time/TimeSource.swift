import Foundation

/// Where "now" comes from.
///
/// View and projection code never reads `Date()` directly, so demo mode and unit tests
/// can pin time (plan step 01: "数据和时间可重复"; plan test 01-04: offline domain tests).
protocol TimeSource: Sendable {
    var now: Date { get }
    var kindDescription: String { get }
}

/// Wall-clock time from the device.
struct SystemTimeSource: TimeSource {
    var now: Date { Date() }
    var kindDescription: String { "系统时间" }
}

/// A single frozen instant. Used by demo mode and by time-projection tests.
struct FixedTimeSource: TimeSource {
    let instant: Date

    var now: Date { instant }
    var kindDescription: String { "固定时间" }
}
