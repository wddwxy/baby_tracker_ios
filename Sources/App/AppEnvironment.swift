import Foundation
import Observation

/// Everything the root view needs for one launch of the app.
///
/// Step 01 assembles only the shell: a demo data source and the (still non-functional)
/// connection controller. The auth, API and sync layers are added in steps 02-09 and
/// get injected here rather than being reached for globally.
@MainActor
@Observable
final class AppEnvironment {
    let mode: AppMode
    let timeSource: TimeSource
    let connection: ConnectionController
    let showsDiagnostics: Bool

    /// The resolved demo dataset, or `nil` in live mode.
    let demoDataset: DemoDataset?

    init(
        mode: AppMode,
        timeSource: TimeSource,
        connection: ConnectionController,
        showsDiagnostics: Bool,
        demoData: DemoDataProviding = DemoDataProvider()
    ) {
        self.mode = mode
        self.timeSource = timeSource
        self.connection = connection
        self.showsDiagnostics = showsDiagnostics
        self.demoDataset = mode.demoDataset.map(demoData.dataset)
    }

    /// Reads the launch arguments and environment, then builds the matching environment.
    static func launch(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> AppEnvironment {
        let options = LaunchOptions.parse(defaults: defaults, environment: environment)

        let timeSource: TimeSource
        if let fixedNow = options.fixedNow {
            timeSource = FixedTimeSource(instant: fixedNow)
        } else if let dataset = options.mode.demoDataset {
            // Demo mode always pins time so the same dataset always renders the same
            // relative times (plan test 01-05).
            timeSource = FixedTimeSource(instant: DemoFixtures.captureInstant(for: dataset))
        } else {
            timeSource = SystemTimeSource()
        }

        return AppEnvironment(
            mode: options.mode,
            timeSource: timeSource,
            connection: ConnectionController(),
            showsDiagnostics: options.showsDiagnostics
        )
    }
}
