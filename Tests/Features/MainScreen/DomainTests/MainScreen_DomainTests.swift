import XCTest
@testable import MainScreen_Domain

final class MainScreen_DomainTests: XCTestCase {
    func testDomainModelHoldsItsFields() {
        let model = DomainModel(id: 1, title: "Title", body: "Body")
        XCTAssertEqual(model.id, 1)
        XCTAssertEqual(model.title, "Title")
        XCTAssertEqual(model.body, "Body")
    }
}
