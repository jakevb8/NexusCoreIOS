import XCTest
@testable import NexusCoreIOS

final class ModelsTests: XCTestCase {

    // MARK: - AssetStatus

    func testAssetStatusRawValues() {
        XCTAssertEqual(AssetStatus.available.rawValue, "AVAILABLE")
        XCTAssertEqual(AssetStatus.inUse.rawValue, "IN_USE")
        XCTAssertEqual(AssetStatus.maintenance.rawValue, "MAINTENANCE")
        XCTAssertEqual(AssetStatus.retired.rawValue, "RETIRED")
    }

    func testAssetStatusDisplayNames() {
        XCTAssertEqual(AssetStatus.available.displayName, "AVAILABLE")
        XCTAssertEqual(AssetStatus.inUse.displayName, "IN USE")
        XCTAssertEqual(AssetStatus.maintenance.displayName, "MAINTENANCE")
        XCTAssertEqual(AssetStatus.retired.displayName, "RETIRED")
    }

    func testAssetStatusColors() {
        XCTAssertEqual(AssetStatus.available.color, "#16A34A")
        XCTAssertEqual(AssetStatus.inUse.color, "#2563EB")
        XCTAssertEqual(AssetStatus.maintenance.color, "#D97706")
        XCTAssertEqual(AssetStatus.retired.color, "#6B7280")
    }

    func testAssetStatusCaseIterable() {
        XCTAssertEqual(AssetStatus.allCases.count, 4)
    }

    func testAssetStatusDecodable() throws {
        let json = #"{"status":"IN_USE"}"#
        struct Wrapper: Decodable { let status: AssetStatus }
        let result = try JSONDecoder().decode(Wrapper.self, from: Data(json.utf8))
        XCTAssertEqual(result.status, .inUse)
    }

    // MARK: - Role

    func testRoleRawValues() {
        XCTAssertEqual(Role.superadmin.rawValue, "SUPERADMIN")
        XCTAssertEqual(Role.orgManager.rawValue, "ORG_MANAGER")
        XCTAssertEqual(Role.assetManager.rawValue, "ASSET_MANAGER")
        XCTAssertEqual(Role.viewer.rawValue, "VIEWER")
    }

    func testRoleCaseIterable() {
        XCTAssertEqual(Role.allCases.count, 4)
    }

    // MARK: - BackendChoice

    func testBackendChoiceBaseURLs() {
        XCTAssertEqual(BackendChoice.js.baseURL, "https://nexus-coreapi-production.up.railway.app/api/v1")
        XCTAssertEqual(BackendChoice.dotnet.baseURL, "https://nexuscoredotnet-production.up.railway.app/api/v1")
    }

    func testBackendChoiceLabels() {
        XCTAssertFalse(BackendChoice.js.label.isEmpty)
        XCTAssertFalse(BackendChoice.dotnet.label.isEmpty)
    }

    // MARK: - PaginatedEvents

    func testPaginatedEventsResolvesJSMeta() throws {
        let json = """
        {
            "data": [],
            "meta": { "total": 42, "page": 3, "perPage": 50 }
        }
        """
        let result = try JSONDecoder().decode(PaginatedEvents.self, from: Data(json.utf8))
        XCTAssertEqual(result.resolvedTotal(), 42)
        XCTAssertEqual(result.resolvedPage(), 3)
    }

    func testPaginatedEventsResolvesDotNetFlatFields() throws {
        let json = """
        {
            "data": [],
            "total": 99,
            "page": 2,
            "perPage": 50
        }
        """
        let result = try JSONDecoder().decode(PaginatedEvents.self, from: Data(json.utf8))
        XCTAssertEqual(result.resolvedTotal(), 99)
        XCTAssertEqual(result.resolvedPage(), 2)
    }

    func testPaginatedEventsDefaultsWhenEmpty() throws {
        let json = #"{"data":[]}"#
        let result = try JSONDecoder().decode(PaginatedEvents.self, from: Data(json.utf8))
        XCTAssertEqual(result.resolvedTotal(), 0)
        XCTAssertEqual(result.resolvedPage(), 1)
    }

    // MARK: - KafkaEvent

    func testKafkaEventDecoding() throws {
        let json = """
        {
            "id": "evt-1",
            "organizationId": "org-1",
            "assetId": "asset-1",
            "assetName": "Laptop A",
            "previousStatus": "AVAILABLE",
            "newStatus": "IN_USE",
            "actorId": "user-1",
            "occurredAt": "2025-01-01T10:00:00Z",
            "createdAt": "2025-01-01T10:00:01Z"
        }
        """
        let event = try JSONDecoder().decode(KafkaEvent.self, from: Data(json.utf8))
        XCTAssertEqual(event.id, "evt-1")
        XCTAssertEqual(event.assetName, "Laptop A")
        XCTAssertEqual(event.previousStatus, "AVAILABLE")
        XCTAssertEqual(event.newStatus, "IN_USE")
    }

    // MARK: - Asset

    func testAssetDecoding() throws {
        let json = """
        {
            "id": "a-1",
            "name": "Forklift",
            "sku": "FL-001",
            "status": "AVAILABLE",
            "organizationId": "org-1",
            "createdAt": "2025-01-01T00:00:00Z"
        }
        """
        let asset = try JSONDecoder().decode(Asset.self, from: Data(json.utf8))
        XCTAssertEqual(asset.id, "a-1")
        XCTAssertEqual(asset.name, "Forklift")
        XCTAssertEqual(asset.status, .available)
        XCTAssertNil(asset.description)
        XCTAssertNil(asset.assignedTo)
    }
}
