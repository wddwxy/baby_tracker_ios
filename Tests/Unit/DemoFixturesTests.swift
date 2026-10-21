import XCTest

@testable import LittleNest

/// Demo datasets must be fixed and repeatable, and the checked-in JSON fixtures must
/// stay decodable in the shape of `DemoDataset` (plan tests 01-05 and 01-04).
final class DemoFixturesTests: XCTestCase {
    private let expectedEntryIDs = [
        "f1-diaper-1",
        "f1-bottle-1",
        "f1-breastfeeding-1",
        "f1-sleep-1",
        "f1-pump-1",
        "f1-solids-1",
        "f1-growth-1",
        "f1-health-1",
    ]

    // MARK: - In-code datasets

    func testCaptureInstantIsFixed() {
        XCTAssertEqual(DemoFixtures.captureEpoch, 1_792_112_400)
        XCTAssertEqual(
            DemoFixtures.captureInstant(for: .f1),
            Date(timeIntervalSince1970: 1_792_112_400)
        )
        XCTAssertEqual(
            DemoFixtures.captureInstant(for: .f0),
            DemoFixtures.captureInstant(for: .f1)
        )
    }

    func testF0IsEmpty() {
        let dataset = DemoFixtures.dataset(for: .f0)

        XCTAssertEqual(dataset.id, .f0)
        XCTAssertNil(dataset.profile)
        XCTAssertTrue(dataset.recentEntries.isEmpty)
        XCTAssertEqual(dataset.timeZoneIdentifier, DemoFixtures.timeZoneIdentifier)
    }

    func testF1IsFullyPopulated() {
        let dataset = DemoFixtures.dataset(for: .f1)

        XCTAssertEqual(dataset.id, .f1)
        XCTAssertNotNil(dataset.profile)
        XCTAssertEqual(dataset.recentEntries.map(\.id), expectedEntryIDs)
        XCTAssertEqual(Set(dataset.recentEntries.map(\.kind)).count, DemoEntryKind.allCases.count)
    }

    func testF1HasNoFutureRecords() {
        let dataset = DemoFixtures.dataset(for: .f1)

        for entry in dataset.recentEntries {
            XCTAssertLessThan(entry.occurredAt, dataset.capturedAt, "\(entry.id) is not in the past")
        }
    }

    func testF1IsOrderedNewestFirst() {
        let instants = DemoFixtures.dataset(for: .f1).recentEntries.map(\.occurredAt)

        XCTAssertEqual(instants, instants.sorted(by: >))
    }

    func testDatasetsAreDeterministic() {
        XCTAssertEqual(DemoFixtures.dataset(for: .f0), DemoFixtures.dataset(for: .f0))
        XCTAssertEqual(DemoFixtures.dataset(for: .f1), DemoFixtures.dataset(for: .f1))
    }

    func testDatasetTimeZoneResolves() {
        XCTAssertEqual(DemoFixtures.dataset(for: .f1).timeZone.identifier, "Asia/Shanghai")
    }

    func testDefaultProviderMatchesFixtures() {
        XCTAssertEqual(DemoDataProvider().dataset(.f1), DemoFixtures.dataset(for: .f1))
    }

    // MARK: - JSON fixtures

    func testF0JSONFixtureDecodes() throws {
        let decoded = try loadFixture("F0")

        XCTAssertEqual(decoded.id, .f0)
        XCTAssertEqual(decoded.capturedAt, DemoFixtures.captureInstant(for: .f0))
        XCTAssertNil(decoded.profile)
        XCTAssertTrue(decoded.recentEntries.isEmpty)
    }

    func testF1JSONFixtureDecodes() throws {
        let decoded = try loadFixture("F1")
        let inCode = DemoFixtures.dataset(for: .f1)

        XCTAssertEqual(decoded.id, .f1)
        XCTAssertEqual(decoded.capturedAt, inCode.capturedAt)
        XCTAssertEqual(decoded.timeZoneIdentifier, inCode.timeZoneIdentifier)
        XCTAssertEqual(decoded.profile, inCode.profile)
        XCTAssertEqual(decoded.settings, inCode.settings)
        XCTAssertEqual(decoded.recentEntries.map(\.id), expectedEntryIDs)
        XCTAssertEqual(decoded.recentEntries.map(\.occurredAt), inCode.recentEntries.map(\.occurredAt))
        XCTAssertEqual(decoded.recentEntries.map(\.kind), inCode.recentEntries.map(\.kind))
    }

    private func loadFixture(_ name: String) throws -> DemoDataset {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(
            bundle.url(forResource: name, withExtension: "json"),
            "\(name).json is missing from the test bundle"
        )
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DemoDataset.self, from: data)
    }
}
