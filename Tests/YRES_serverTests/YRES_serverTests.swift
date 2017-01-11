import XCTest
@testable import YRES_server

class YRES_serverTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(YRES_server().text, "Hello, World!")
    }


    static var allTests : [(String, (YRES_serverTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
