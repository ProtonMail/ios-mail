@testable import ProtonMail
import XCTest

class ConversationFeatureFlagServiceTests: XCTestCase {

    var sut: ConversationFeatureFlagService!
    var apiServiceSpy: APIServiceSpy!

    override func setUp() {
        super.setUp()

        apiServiceSpy = APIServiceSpy()
        sut = ConversationFeatureFlagService(apiService: apiServiceSpy)
    }

    override func tearDown() {
        super.tearDown()

        apiServiceSpy = nil
        sut = nil
    }

    func testGetConversationFlagSuccess() {
        var result: Bool?
        var error: Error?
        let finallyExpectation = XCTestExpectation()

        sut.getConversationFlag()
            .done { result = $0 }
            .catch { error = $0 }
            .finally { finallyExpectation.fulfill() }

        XCTAssertEqual(apiServiceSpy.invokedRequestWithMethod, [.get])
        XCTAssertEqual(apiServiceSpy.invokedRequestWithPath, ["/core/v4/features/ThreadingIOS"])
        XCTAssertEqual(apiServiceSpy.invokedRequestWithParameters.count, 1)
        let headers = apiServiceSpy.invokedRequestWithHeaders.first as? [String: Int]
        XCTAssertEqual(headers?["x-pm-apiversion"], 3)
        XCTAssertEqual(apiServiceSpy.invokedRequestWithCompletion.count, 1)

        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let validJson: [String: Any] = [
            "Code": 1000,
            "Feature": [
                "Value": true
            ]
        ]
        apiServiceSpy.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, validJson, nil)

        wait(for: [finallyExpectation], timeout: 1)

        XCTAssertTrue(result ?? false)
        XCTAssertNil(error)
    }

    func testGetConversationFlagFailureCode() {
        var result: Bool?
        var error: Error?
        let finallyExpectation = XCTestExpectation()

        sut.getConversationFlag()
            .done { result = $0 }
            .catch { error = $0 }
            .finally { finallyExpectation.fulfill() }

        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let jsonWithErrorCode: [String: Any] = [
            "Code": 100,
        ]
        apiServiceSpy.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, nil)

        wait(for: [finallyExpectation], timeout: 1)

        XCTAssertNil(result)
        XCTAssertNotNil(error)
    }

    func testGetConversationFlagFailureResponse() {
        var result: Bool?
        var error: Error?
        let finallyExpectation = XCTestExpectation()

        sut.getConversationFlag()
            .done { result = $0 }
            .catch { error = $0 }
            .finally { finallyExpectation.fulfill() }

        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let stubbedError = NSError(domain: "", code: 999, localizedDescription: "")
        urlSessionDataTaskStub.stubbedError = stubbedError
        let jsonWithErrorCode: [String: Any] = [:]
        apiServiceSpy.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, nil)

        wait(for: [finallyExpectation], timeout: 1)

        XCTAssertNil(result)
        XCTAssertEqual(error as NSError?, stubbedError)
    }

}
