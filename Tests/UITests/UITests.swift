import XCTest
@testable import UI

final class UITests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(UIModule.self)
    }
}
