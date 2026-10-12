import XCTest
@testable import Resources

final class ResourcesTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(R.self)
    }
}
