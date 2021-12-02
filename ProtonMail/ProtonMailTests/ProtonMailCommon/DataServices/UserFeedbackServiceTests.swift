// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
import ProtonCore_TestingToolkit
import ProtonCore_Services

@testable import ProtonMail

class UserFeedbackServiceTests: XCTestCase {
    static let waitExpectationTimeoutTime = 2.0
    
    var apiService =  APIServiceMock()
    
    func testThatRequestParametersAreCorrectyAssembled() throws {
        let expectedType = "Type"
        let expectedScore = 1
        let expectedText = "Text"
        let feedback = UserFeedback(type: expectedType, score: expectedScore, text: expectedText)
        let request = UserFeedbackRequest(with: feedback)
        guard let params = request.parameters else {
            XCTFail("Failed to materialize parameters")
            return
        }

        XCTAssertEqual(params[UserFeedbackRequest.ParamKeys.feedback.rawValue] as? String, expectedText)
        XCTAssertEqual(params[UserFeedbackRequest.ParamKeys.score.rawValue] as? Int, expectedScore)
        XCTAssertEqual(params[UserFeedbackRequest.ParamKeys.feedbackType.rawValue] as? String, expectedType)
    }

    func testThatCorrectResponseCodeHandledWithoutError() {
        apiService.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            guard path.contains(UserFeedbackRequest.apiPath) else {
                XCTFail("Unexpected path")
                return
            }
            completion?(nil, ["Code": UserFeedbackRequest.responseSuccessCode], nil)
        }
        let callExpectation = expectation(description: "Should get response back")
        let service = UserFeedbackService(apiService: apiService as APIService)
        let feedback = UserFeedback(type: "", score: 0, text: "")
        service.send(feedback) { error in
            XCTAssertNil(error)
            callExpectation.fulfill()
        }
        waitForExpectations(timeout: Self.waitExpectationTimeoutTime, handler: nil)
    }
    
    func testThatWrongResponseCodeTriggersError() {
        apiService.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            guard path.contains(UserFeedbackRequest.apiPath) else {
                XCTFail("Unexpected path")
                return
            }
            completion?(nil, ["Code": -1], nil)
        }
        let callExpectation = expectation(description: "Should get response back")
        let service = UserFeedbackService(apiService: apiService as APIService)
        let feedback = UserFeedback(type: "", score: 0, text: "")
        service.send(feedback) { error in
            XCTAssertNotNil(error)
            callExpectation.fulfill()
        }
        waitForExpectations(timeout: Self.waitExpectationTimeoutTime, handler: nil)
    }
    
    func testThatTooLongTypeIsNotAllowed() {
        let callExpectation = expectation(description: "Should get response back")
        let validationExpectation = expectation(description: "Validation callback is expected")
        let service = UserFeedbackService(apiService: apiService as APIService)
        let feedback = UserFeedback(type: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent luctus quam venenatis finibus iaculis. Mauris lobortis blandit molestie. Phasellus non tortor quam. Cras vel arcu ultricies, porta tortor ac, blandit leo. Proin nibh libero, placerat quis massa a, tincidunt consectetur mi. Aliquam et aliquet urna, vitae ultricies dolor. Cras sed ligula risus. Curabitur in ullamcorper ligula. Interdum et malesuada fames ac ante ipsum primis in faucibus. Curabitur ultrices mi ac purus ultrices faucibus.", score: 0, text: "")
        service.send(feedback) { error in
            XCTAssertNotNil(error)
            switch error {
            case .feedbackTypeIsTooLong:
                validationExpectation.fulfill()
            default:
                XCTFail("Unexpected error")
            }
            callExpectation.fulfill()
        }
        waitForExpectations(timeout: Self.waitExpectationTimeoutTime, handler: nil)
    }
}
