import XCTest
@testable import Core

final class CoreTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(CoreModule.self)
    }
}
