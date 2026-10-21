import XCTest

/// Plan test 01-01: a clean checkout launches into the shell.
final class ShellLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesIntoTheFourTabShell() {
        let app = XCUIApplication.launchLive()

        XCTAssertTrue(app.tab("首页").waitForExistence(timeout: 30))
        XCTAssertTrue(app.tab("记录").exists)
        XCTAssertTrue(app.tab("趋势").exists)
        XCTAssertTrue(app.tab("设置").exists)
    }

    func testLiveLaunchDoesNotShowDemoData() {
        let app = XCUIApplication.launchLive()

        XCTAssertTrue(app.tab("首页").waitForExistence(timeout: 30))
        XCTAssertFalse(app.staticTexts["演示数据"].exists)
    }

    func testLiveHomeAsksForAConnectionInsteadOfInventingRecords() {
        let app = XCUIApplication.launchLive()

        XCTAssertTrue(app.identified(AccessibilityID.homeUnconnected).waitForExistence(timeout: 30))
        XCTAssertFalse(app.identified(AccessibilityID.homeProfileCard).exists)
    }

    func testLiveHistoryAsksForAConnectionInsteadOfInventingRecords() {
        let app = XCUIApplication.launchLive()

        XCTAssertTrue(app.tab("记录").waitForExistence(timeout: 30))
        app.tab("记录").tap()

        XCTAssertTrue(app.identified(AccessibilityID.historyUnconnected).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["尚未连接 Home Assistant"].exists)
    }

    func testTrendsTabDoesNotInventCharts() {
        let app = XCUIApplication.launchLive()

        XCTAssertTrue(app.tab("趋势").waitForExistence(timeout: 30))
        app.tab("趋势").tap()

        XCTAssertTrue(app.staticTexts["趋势尚未实现"].waitForExistence(timeout: 10))
    }
}
