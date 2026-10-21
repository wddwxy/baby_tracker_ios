import XCTest

/// Plan test 01-05: demo mode with a fixed dataset is repeatable and never pretends to be
/// connected to Home Assistant.
final class DemoModeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDemoBannerIsPinnedAndLabelled() {
        let app = XCUIApplication.launchDemo("F1")

        XCTAssertTrue(app.staticTexts["演示数据"].waitForExistence(timeout: 30))

        let stamp = app.identified(AccessibilityID.demoBannerStamp)
        XCTAssertTrue(stamp.exists)
        XCTAssertTrue(stamp.label.contains("2026-10-16 09:00"), stamp.label)
        XCTAssertTrue(stamp.label.contains("Asia/Shanghai"), stamp.label)
    }

    func testDemoBannerSurvivesTabChanges() {
        let app = XCUIApplication.launchDemo("F1")

        XCTAssertTrue(app.staticTexts["演示数据"].waitForExistence(timeout: 30))

        app.tab("记录").tap()
        XCTAssertTrue(app.staticTexts["演示数据"].exists)

        app.tab("设置").tap()
        XCTAssertTrue(app.staticTexts["演示数据"].exists)
    }

    func testF1ShowsFixedEntriesWithFrozenRelativeTime() {
        let app = XCUIApplication.launchDemo("F1")

        XCTAssertTrue(app.identified(AccessibilityID.homeProfileCard).waitForExistence(timeout: 30))

        let newest = app.identified(AccessibilityID.homeEntryRow("f1-diaper-1"))
        XCTAssertTrue(newest.waitForExistence(timeout: 10))
        XCTAssertTrue(newest.label.contains("35 分钟前"), newest.label)
    }

    func testF0ShowsEmptyStates() {
        let app = XCUIApplication.launchDemo("F0")

        XCTAssertTrue(app.identified(AccessibilityID.homeEmptyProfile).waitForExistence(timeout: 30))
        XCTAssertTrue(app.identified(AccessibilityID.homeEmptyEntries).exists)
        XCTAssertFalse(app.identified(AccessibilityID.homeProfileCard).exists)
    }

    func testDemoModeNeverClaimsAConnection() {
        let app = XCUIApplication.launchDemo("F1")

        XCTAssertTrue(app.tab("设置").waitForExistence(timeout: 30))
        app.tab("设置").tap()

        let modeRow = app.identified(AccessibilityID.settingsModeRow)
        XCTAssertTrue(modeRow.waitForExistence(timeout: 10))
        XCTAssertTrue(modeRow.label.contains("演示数据"), modeRow.label)
        XCTAssertFalse(modeRow.label.contains("已连接"), modeRow.label)
        XCTAssertFalse(app.staticTexts["已连接"].exists)
    }

    func testDataAndTimeAreRepeatableAcrossLaunches() {
        let app = XCUIApplication.launchDemo("F1")
        XCTAssertTrue(app.staticTexts["演示数据"].waitForExistence(timeout: 30))

        let firstRun = app.identified(AccessibilityID.homeEntryRow("f1-diaper-1"))
        XCTAssertTrue(firstRun.waitForExistence(timeout: 10))
        let firstRunLabel = firstRun.label

        app.terminate()

        app.launch()
        XCTAssertTrue(app.staticTexts["演示数据"].waitForExistence(timeout: 30))

        let secondRun = app.identified(AccessibilityID.homeEntryRow("f1-diaper-1"))
        XCTAssertTrue(secondRun.waitForExistence(timeout: 10))

        XCTAssertEqual(secondRun.label, firstRunLabel)
    }
}
