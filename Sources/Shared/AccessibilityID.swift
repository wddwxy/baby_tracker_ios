import Foundation

/// Accessibility identifiers shared by the views and the UI tests.
///
/// Keeping them in one place stops the tests from depending on visible copy that will be
/// localized in step 20.
/// Attach identifiers to the semantic element being queried. An identifier on a
/// transparent Group or banner stack can override the identifiers of its children.
enum AccessibilityID {
    static let demoBannerStamp = "demo.banner.stamp"

    static let homeProfileCard = "home.profile"
    static let homeEmptyProfile = "home.empty.profile"
    static let homeEmptyEntries = "home.empty.entries"
    static let homeUnconnected = "home.unconnected"
    static let homeOpenConnection = "home.openConnection"

    static let historyUnconnected = "history.unconnected"

    static let trendsRoot = "trends.root"

    static let settingsRoot = "settings.root"
    static let settingsModeRow = "settings.mode"
    static let settingsOpenConnection = "settings.openConnection"
    static let settingsOpenDiagnostics = "settings.openDiagnostics"

    static let connectionSetupRoot = "connection.setup"
    static let connectionAddressField = "connection.address"
    static let connectionConnectButton = "connection.connect"
    static let connectionProgress = "connection.progress"
    static let connectionProblemCard = "connection.problem"

    static let diagnosticsRoot = "diagnostics.root"

    static func homeEntryRow(_ entryID: String) -> String { "home.entry.\(entryID)" }
    static func historyEntryRow(_ entryID: String) -> String { "history.entry.\(entryID)" }
}
