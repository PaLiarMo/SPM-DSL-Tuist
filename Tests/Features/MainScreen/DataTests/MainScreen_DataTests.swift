import XCTest
@testable import MainScreen_Data

final class MainScreen_DataTests: XCTestCase {
    func testDataModelDecodesFromJSON() throws {
        let json = """
        {"id": 1, "userId": 2, "title": "Title", "body": "Body"}
        """.data(using: .utf8)!

        let model = try JSONDecoder().decode(DataModel.self, from: json)
        XCTAssertEqual(model.id, 1)
        XCTAssertEqual(model.title, "Title")
        XCTAssertEqual(model.body, "Body")
    }
}
