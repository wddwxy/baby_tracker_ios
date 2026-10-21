import Foundation

/// Locale-independent absolute stamps for demo data.
///
/// Demo mode pins a time zone from the dataset so the rendered timestamps are repeatable
/// on any device (plan test 01-05). Real user-facing formatting follows the user's own
/// time zone and format and is built in step 02 / step 20.
enum FixedStampFormatter {
    /// "2026-10-16 09:00".
    static func label(_ instant: Date, timeZone: TimeZone) -> String {
        string(from: instant, timeZone: timeZone, format: "yyyy-MM-dd HH:mm")
    }

    /// "09:00".
    static func clockLabel(_ instant: Date, timeZone: TimeZone) -> String {
        string(from: instant, timeZone: timeZone, format: "HH:mm")
    }

    private static func string(from instant: Date, timeZone: TimeZone, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: instant)
    }
}
