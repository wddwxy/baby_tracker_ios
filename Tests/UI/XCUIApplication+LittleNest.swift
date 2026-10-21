import XCTest

extension XCUIApplication {
    /// Launches in demo mode with a fixed dataset (plan test 01-05).
    @discardableResult
    static func launchDemo(_ dataset: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-LittleNestDemoDataset", dataset] + extraArguments
        app.launch()
        return app
    }

    /// Launches in live mode, which in step 01 means "not connected yet".
    @discardableResult
    static func launchLive(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-LittleNestMode", "live"] + extraArguments
        app.launch()
        return app
    }

    /// Finds an element by accessibility identifier without assuming its element type.
    func identified(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// A tab-bar button by its visible title.
    func tab(_ title: String) -> XCUIElement {
        tabBars.buttons[title]
    }
}
