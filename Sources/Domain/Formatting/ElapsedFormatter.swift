import Foundation

/// Deterministic, locale-independent relative time labels.
///
/// Provisional: step 02 builds the shared time and formatting layer, and step 20 adds
/// real localization. The shell needs a stable label because UI tests assert on it and
/// because demo mode must not depend on the device locale.
enum ElapsedFormatter {
    /// "刚刚" / "5 分钟前" / "3 小时前" / "2 天前".
    ///
    /// Future instants clamp to "刚刚" instead of rendering a negative duration.
    static func shortLabel(from instant: Date, to now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(instant).rounded(.down))
        guard seconds >= 60 else { return "刚刚" }

        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) 分钟前" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours) 小时前" }

        return "\(hours / 24) 天前"
    }

    /// Whole days between two instants, clamped at zero.
    static func dayCount(from instant: Date, to now: Date) -> Int {
        max(0, Int(now.timeIntervalSince(instant) / 86_400))
    }

    /// "179 天".
    static func dayCountLabel(from instant: Date, to now: Date) -> String {
        "\(dayCount(from: instant, to: now)) 天"
    }
}
