import XCTest
@testable import DI

final class DITests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(DIModule.self)
    }
}
