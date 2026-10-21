import XCTest

@testable import LittleNest

/// Address validation must stay pure and offline so it can run without a Home Assistant
/// instance and without credentials (plan test 01-04).
final class AddressValidatorTests: XCTestCase {
    func testEmptyAddressIsReportedSeparately() {
        XCTAssertEqual(AddressValidator.problem(with: ""), .emptyAddress)
        XCTAssertEqual(AddressValidator.problem(with: "   "), .emptyAddress)
    }

    func testAddressWithoutSchemeIsRejected() {
        XCTAssertEqual(AddressValidator.problem(with: "homeassistant.local:8123"), .malformedAddress)
    }

    func testNonHTTPSSchemeIsRejected() {
        XCTAssertEqual(AddressValidator.problem(with: "ftp://homeassistant.local"), .malformedAddress)
    }

    func testSchemeWithoutHostIsRejected() {
        XCTAssertEqual(AddressValidator.problem(with: "http://"), .malformedAddress)
    }

    func testEmbeddedCredentialsAreRejected() {
        // The address must never carry secrets; OAuth owns authentication (step 03).
        XCTAssertEqual(
            AddressValidator.problem(with: "http://user:secret@homeassistant.local:8123"),
            .malformedAddress
        )
    }

    func testPlainLocalAddressIsAccepted() {
        XCTAssertNil(AddressValidator.problem(with: "http://homeassistant.local:8123"))
    }

    func testHTTPSAddressIsAccepted() {
        XCTAssertNil(AddressValidator.problem(with: "https://ha.example.com"))
    }

    func testSurroundingWhitespaceIsTrimmed() {
        XCTAssertNil(AddressValidator.problem(with: "  http://192.168.1.10:8123  "))
    }
}
