import XCTest

/// The connection skeleton must give a distinct, honest answer for each failure category
/// and must never fake a successful session (plan step 01 and step 03's UI contract).
final class ConnectionSetupUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openConnectionSetup(in app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(app.tab("设置").waitForExistence(timeout: 30))
        app.tab("设置").tap()

        let entry = app.identified(AccessibilityID.settingsOpenConnection)
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()

        let field = app.identified(AccessibilityID.connectionAddressField)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        return field
    }

    private func enter(_ address: String, into field: XCUIElement, in app: XCUIApplication) {
        field.tap()
        field.typeText(address)
        app.identified(AccessibilityID.connectionConnectButton).tap()
    }

    func testAddressWithoutSchemeReportsTheAddressProblem() {
        let app = XCUIApplication.launchLive()
        let field = openConnectionSetup(in: app)

        enter("homeassistant.local:8123", into: field, in: app)

        let card = app.identified(AccessibilityID.connectionProblemCard)
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertTrue(card.label.contains("地址无法识别"), card.label)
    }

    func testValidAddressReportsThatTheFlowIsNotBuiltYet() {
        let app = XCUIApplication.launchLive()
        let field = openConnectionSetup(in: app)

        enter("http://homeassistant.local:8123", into: field, in: app)

        let card = app.identified(AccessibilityID.connectionProblemCard)
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertTrue(card.label.contains("连接功能尚未实现"), card.label)
        XCTAssertFalse(card.label.contains("已连接"), card.label)
    }

    func testEditingTheAddressClearsTheProblemCard() {
        let app = XCUIApplication.launchLive()
        let field = openConnectionSetup(in: app)

        enter("homeassistant.local:8123", into: field, in: app)
        XCTAssertTrue(app.identified(AccessibilityID.connectionProblemCard).waitForExistence(timeout: 10))

        field.tap()
        field.typeText(":")

        XCTAssertFalse(app.identified(AccessibilityID.connectionProblemCard).exists)
    }

    func testDemoModeKeepsTheBannerOnTheConnectionScreen() {
        let app = XCUIApplication.launchDemo("F1")
        _ = openConnectionSetup(in: app)

        XCTAssertTrue(app.staticTexts["演示数据"].exists)
        XCTAssertFalse(app.identified(AccessibilityID.connectionProblemCard).exists)
    }

    func testDiagnosticsAreOnlyReachableWhenRequested() {
        let app = XCUIApplication.launchLive()
        XCTAssertTrue(app.tab("设置").waitForExistence(timeout: 30))
        app.tab("设置").tap()

        XCTAssertFalse(app.identified(AccessibilityID.settingsOpenDiagnostics).exists)

        app.terminate()

        let diagnosticApp = XCUIApplication()
        diagnosticApp.launchArguments = ["-LittleNestMode", "live", "-LittleNestDiagnostics", "YES"]
        diagnosticApp.launch()
        XCTAssertTrue(diagnosticApp.tab("设置").waitForExistence(timeout: 30))
        diagnosticApp.tab("设置").tap()

        let entry = diagnosticApp.identified(AccessibilityID.settingsOpenDiagnostics)
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()

        XCTAssertTrue(diagnosticApp.identified(AccessibilityID.diagnosticsRoot).waitForExistence(timeout: 10))
    }
}
