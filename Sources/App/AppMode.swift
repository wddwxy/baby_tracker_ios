import Foundation

/// How this launch of the prototype obtains its data.
///
/// Step 01 ships no Home Assistant session yet (that is step 03), so the mode decides
/// whether the app shows the real, unconnected state or a fixed synthetic dataset.
///
/// The mode is always visible in the UI. A demo launch must never look like a
/// successful Home Assistant connection (plan test 01-05).
enum AppMode: Equatable, Sendable {
    /// Real data from a Home Assistant instance.
    ///
    /// Without a session the app shows the connection setup screen instead of
    /// fabricating content.
    case live

    /// Synthetic, fixed data. Never performs network work and never reports "connected".
    case demo(DemoDatasetID)
}

extension AppMode {
    var isDemo: Bool {
        if case .demo = self { return true }
        return false
    }

    /// The active demo dataset, or `nil` in live mode.
    var demoDataset: DemoDatasetID? {
        if case let .demo(dataset) = self { return dataset }
        return nil
    }

    /// Short label used by the demo banner and the settings screen.
    var displayName: String {
        switch self {
        case .live:
            return "真实数据"
        case let .demo(dataset):
            return "演示数据 · \(dataset.displayName)"
        }
    }
}
