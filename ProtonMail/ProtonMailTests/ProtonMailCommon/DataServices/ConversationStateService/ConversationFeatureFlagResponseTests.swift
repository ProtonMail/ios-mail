@testable import ProtonMail
import XCTest

class ConversationFeatureFlagResponseTests: XCTestCase {

    func testParseWithCorrectJson() {
        let json: [String: Any] = [
            "Feature": [
                "Value": true
            ]
        ]
        let response = ConversationFeatureFlagResponse()
        let result = response.ParseResponse(json)
        XCTAssertTrue(result)
        XCTAssertTrue(response.isConversationModeEnabled ?? false)
    }

    func testParseWithIncorrectJson() {
        let json: [String: Any] = [
            "Feature": [
                "unknown_key": "value"
            ]
        ]
        let response = ConversationFeatureFlagResponse()
        let result = response.ParseResponse(json)
        XCTAssertFalse(result)
        XCTAssertNil(response.isConversationModeEnabled)
    }

}
