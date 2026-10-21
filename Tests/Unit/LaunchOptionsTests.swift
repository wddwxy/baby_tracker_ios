import XCTest

@testable import LittleNest

/// Covers launch-argument parsing, including the arguments the UI tests use to select
/// demo mode. Runs fully offline (plan test 01-04).
final class LaunchOptionsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "little-nest.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testDefaultsToLiveMode() {
        let options = LaunchOptions.parse(defaults: makeDefaults(), environment: [:])

        XCTAssertEqual(options.mode, .live)
        XCTAssertNil(options.fixedNow)
        XCTAssertFalse(options.showsDiagnostics)
    }

    func testUnknownModeNeverBecomesDemoData() {
        let defaults = makeDefaults()
        defaults.set("preview", forKey: LaunchOptions.modeKey)

        XCTAssertEqual(LaunchOptions.parse(defaults: defaults, environment: [:]).mode, .live)
    }

    func testNamingADatasetSelectsDemoMode() {
        let defaults = makeDefaults()
        defaults.set("F1", forKey: LaunchOptions.demoDatasetKey)

        XCTAssertEqual(LaunchOptions.parse(defaults: defaults, environment: [:]).mode, .demo(.f1))
    }

    func testDemoModeWithoutDatasetUsesF1() {
        let defaults = makeDefaults()
        defaults.set("demo", forKey: LaunchOptions.modeKey)

        XCTAssertEqual(LaunchOptions.parse(defaults: defaults, environment: [:]).mode, .demo(.f1))
    }

    func testLiveModeWinsOverAStaleDatasetArgument() {
        let defaults = makeDefaults()
        defaults.set("live", forKey: LaunchOptions.modeKey)
        defaults.set("F1", forKey: LaunchOptions.demoDatasetKey)

        XCTAssertEqual(LaunchOptions.parse(defaults: defaults, environment: [:]).mode, .live)
    }

    func testEnvironmentVariablesAreAccepted() {
        let options = LaunchOptions.parse(
            defaults: makeDefaults(),
            environment: [
                "LITTLENEST_MODE": "demo",
                "LITTLENEST_DEMO_DATASET": "f0",
                "LITTLENEST_DIAGNOSTICS": "1",
            ]
        )

        XCTAssertEqual(options.mode, .demo(.f0))
        XCTAssertTrue(options.showsDiagnostics)
    }

    func testFixedNowArgumentParsesISO8601() {
        let defaults = makeDefaults()
        defaults.set("2026-10-16T01:00:00Z", forKey: LaunchOptions.fixedNowKey)

        let options = LaunchOptions.parse(defaults: defaults, environment: [:])

        XCTAssertEqual(options.fixedNow, Date(timeIntervalSince1970: DemoFixtures.captureEpoch))
    }

    func testUnparsableFixedNowIsIgnored() {
        let defaults = makeDefaults()
        defaults.set("yesterday", forKey: LaunchOptions.fixedNowKey)

        XCTAssertNil(LaunchOptions.parse(defaults: defaults, environment: [:]).fixedNow)
    }

    func testAppModeHelpers() {
        XCTAssertTrue(AppMode.demo(.f1).isDemo)
        XCTAssertFalse(AppMode.live.isDemo)
        XCTAssertEqual(AppMode.demo(.f0).demoDataset, .f0)
        XCTAssertNil(AppMode.live.demoDataset)
        XCTAssertEqual(AppMode.live.displayName, "真实数据")
    }
}
