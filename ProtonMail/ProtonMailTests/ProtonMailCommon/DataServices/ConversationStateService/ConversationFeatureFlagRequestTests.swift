@testable import ProtonMail
import XCTest

class ConversationFeatureFlagRequestTests: XCTestCase {

    func testRequest() {
        let request = ConversationFeatureFlagRequest()
        XCTAssertEqual(request.path, "/core/v4/features/ThreadingIOS")
        XCTAssertEqual(request.method, .get)
    }

}
