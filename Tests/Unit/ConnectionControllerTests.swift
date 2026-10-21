import XCTest

@testable import LittleNest

/// The connection controller must never report a connection in step 01.
@MainActor
final class ConnectionControllerTests: XCTestCase {
    func testInitialStateIsNotConfigured() {
        let controller = ConnectionController()

        XCTAssertEqual(controller.state, .notConfigured)
        XCTAssertEqual(controller.address, "")
        XCTAssertNil(controller.state.problem)
        XCTAssertFalse(controller.state.isConnected)
    }

    func testConnectWithEmptyAddressReportsEmptyAddress() {
        let controller = ConnectionController()
        controller.connect()

        XCTAssertEqual(controller.state, .failed(.emptyAddress))
    }

    func testConnectWithMalformedAddressReportsMalformedAddress() {
        let controller = ConnectionController()
        controller.address = "homeassistant.local:8123"
        controller.connect()

        XCTAssertEqual(controller.state, .failed(.malformedAddress))
    }

    func testConnectWithValidAddressStopsAtTheHonestBarrier() {
        let controller = ConnectionController()
        controller.address = "http://homeassistant.local:8123"

        XCTAssertNil(controller.validateAddress())

        controller.connect()

        XCTAssertEqual(controller.state, .failed(.notAvailableInThisBuild))
        XCTAssertFalse(controller.state.isConnected)
    }

    func testEditingTheAddressClearsAStaleProblem() {
        let controller = ConnectionController()
        controller.connect()
        XCTAssertEqual(controller.state, .failed(.emptyAddress))

        controller.address = "http://homeassistant.local:8123"

        XCTAssertEqual(controller.state, .notConfigured)
    }

    func testSignOutClearsAddressAndState() {
        let controller = ConnectionController()
        controller.address = "http://homeassistant.local:8123"
        controller.connect()

        controller.signOut()

        XCTAssertEqual(controller.address, "")
        XCTAssertEqual(controller.state, .notConfigured)
    }

    func testProgressCopyCoversTheStepThreeStages() {
        XCTAssertNil(ConnectionState.notConfigured.progressDescription)
        XCTAssertNil(ConnectionState.connected(userName: "A").progressDescription)
        XCTAssertNil(ConnectionState.failed(.unreachable).progressDescription)

        XCTAssertEqual(ConnectionState.validatingAddress.progressDescription, "正在检查地址")
        XCTAssertEqual(ConnectionState.authenticating.progressDescription, "正在登录 Home Assistant")
        XCTAssertEqual(ConnectionState.creatingSession.progressDescription, "正在连接 Baby Tracker")
        XCTAssertEqual(ConnectionState.loadingProfile.progressDescription, "正在读取资料")
    }

    func testProblemCopyStaysCategorised() {
        XCTAssertEqual(ConnectionProblem.unreachable.title, "无法连接到该地址")
        XCTAssertEqual(ConnectionProblem.serviceNotStarted.title, "Baby Tracker 未运行")
        XCTAssertEqual(ConnectionProblem.loginRequired.title, "需要重新登录")
        XCTAssertEqual(ConnectionProblem.incompatibleVersion.title, "版本不兼容")

        let titles = Set([
            ConnectionProblem.unreachable.title,
            ConnectionProblem.serviceNotStarted.title,
            ConnectionProblem.loginRequired.title,
            ConnectionProblem.incompatibleVersion.title,
        ])
        XCTAssertEqual(titles.count, 4, "categories must not collapse into one message")
    }
}
