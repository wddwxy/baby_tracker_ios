import XCTest

@testable import LittleNest

/// Assembly rules for one launch: which data source, which clock, and which mode is
/// reported to the UI. Runs offline (plan test 01-04).
@MainActor
final class AppEnvironmentTests: XCTestCase {
    private struct StubDemoData: DemoDataProviding {
        let dataset: DemoDataset
        func dataset(_ id: DemoDatasetID) -> DemoDataset { dataset }
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "little-nest.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testLiveLaunchHasNoDemoDataAndUsesSystemTime() {
        let environment = AppEnvironment.launch(defaults: makeDefaults(), environment: [:])

        XCTAssertEqual(environment.mode, .live)
        XCTAssertNil(environment.demoDataset)
        XCTAssertEqual(environment.timeSource.kindDescription, "系统时间")
        XCTAssertLessThan(abs(environment.timeSource.now.timeIntervalSinceNow), 5)
        XCTAssertFalse(environment.showsDiagnostics)
    }

    func testDemoLaunchPinsTimeToTheDatasetCaptureInstant() {
        let environment = AppEnvironment.launch(
            defaults: makeDefaults(),
            environment: ["LITTLENEST_DEMO_DATASET": "f1"]
        )

        XCTAssertEqual(environment.mode, .demo(.f1))
        XCTAssertEqual(environment.demoDataset?.id, .f1)
        XCTAssertEqual(environment.timeSource.kindDescription, "固定时间")
        XCTAssertEqual(environment.timeSource.now, DemoFixtures.captureInstant(for: .f1))
    }

    func testFixedNowArgumentOverridesTheDemoClock() {
        let override = Date(timeIntervalSince1970: 1_700_000_000)
        let defaults = makeDefaults()
        defaults.set("f0", forKey: LaunchOptions.demoDatasetKey)
        defaults.set("2023-11-14T22:13:20Z", forKey: LaunchOptions.fixedNowKey)

        let environment = AppEnvironment.launch(defaults: defaults, environment: [:])

        XCTAssertEqual(environment.mode, .demo(.f0))
        XCTAssertEqual(environment.timeSource.now, override)
    }

    func testDemoDataProviderIsInjectable() {
        let injected = DemoFixtures.empty
        let environment = AppEnvironment(
            mode: .demo(.f1),
            timeSource: FixedTimeSource(instant: DemoFixtures.captureInstant(for: .f1)),
            connection: ConnectionController(),
            showsDiagnostics: false,
            demoData: StubDemoData(dataset: injected)
        )

        XCTAssertEqual(environment.demoDataset, injected)
        XCTAssertEqual(environment.demoDataset?.id, .f0, "the injected provider must win")
    }

    func testDemoModeIsAlwaysVisibleToTheUi() {
        let environment = AppEnvironment.launch(
            defaults: makeDefaults(),
            environment: ["LITTLENEST_MODE": "demo", "LITTLENEST_DEMO_DATASET": "f1"]
        )

        XCTAssertTrue(environment.mode.isDemo)
        XCTAssertTrue(environment.mode.displayName.contains("演示数据"))
        XCTAssertNotNil(environment.demoDataset)
    }

    func testDiagnosticsFlagIsRead() {
        let environment = AppEnvironment.launch(
            defaults: makeDefaults(),
            environment: ["LITTLENEST_DIAGNOSTICS": "1"]
        )

        XCTAssertTrue(environment.showsDiagnostics)
    }
}
