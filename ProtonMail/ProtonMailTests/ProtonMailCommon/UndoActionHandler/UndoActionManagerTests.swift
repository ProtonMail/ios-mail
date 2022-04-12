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
@testable import ProtonMail
import ProtonCore_TestingToolkit

class UndoActionManagerTests: XCTestCase {

    var sut: UndoActionManager!
    var handlerMock: UndoActionHandlerBaseMock!
    var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        handlerMock = UndoActionHandlerBaseMock()
        apiServiceMock = APIServiceMock()
        sut = UndoActionManager(apiService: apiServiceMock, fetchEventClosure: nil)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        handlerMock = nil
        apiServiceMock = nil
    }

    func testRegisterHandler() {
        XCTAssertNil(sut.handler)
        sut.register(handler: self.handlerMock)
        XCTAssertNotNil(sut.handler)
    }

    func testAddTitleWitchAction() {
        sut.addTitleWithAction(title: "title", action: .archive)
        XCTAssertEqual(sut.undoTitles.count, 1)
        XCTAssertEqual(sut.undoTitles[0].action, .archive)
        XCTAssertEqual(sut.undoTitles[0].title, "title")
    }

    func testAddUndoToken_actionMatched() throws {
        let token = UndoTokenData(token: "token", tokenValidTime: 0)
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)

        sut.addUndoToken(token, undoActionType: .archive)
        XCTAssertTrue(handlerMock.isShowUndoActionCalled)
        let tokenToCheck = try XCTUnwrap(handlerMock.token)
        XCTAssertEqual(tokenToCheck.token, "token")
        XCTAssertEqual(handlerMock.title, "title")
    }

    func testAddUndoToken_actionNotMatched() throws {
        let token = UndoTokenData(token: "token", tokenValidTime: 0)
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)

        sut.addUndoToken(token, undoActionType: .spam)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)
        XCTAssertNil(handlerMock.title)
        XCTAssertNil(handlerMock.token)
    }

    func testAddUndoToken_tokenReturnAfterThreshold_handlerShouldNotBeCalled() {
        let expectation1 = expectation(description: "wait for threshold")
        let token = UndoTokenData(token: "token", tokenValidTime: 0)
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)

        DispatchQueue.main.asyncAfter(deadline: .now() + UndoActionManager.Const.delayThreshold) {
            self.sut.addUndoToken(token, undoActionType: .archive)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: UndoActionManager.Const.delayThreshold + 1, handler: nil)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)
    }

    func testAddUndoToken_tokenReturnBeforeThreshold_handlerShouldNotBeCalled() {
        let expectation1 = expectation(description: "wait for threshold")
        let token = UndoTokenData(token: "token", tokenValidTime: 0)
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sut.addUndoToken(token, undoActionType: .archive)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: UndoActionManager.Const.delayThreshold, handler: nil)
        XCTAssertTrue(handlerMock.isShowUndoActionCalled)
    }

    func testChangeHander_removeAllExistingTitle() {
        sut.addTitleWithAction(title: "title", action: .spam)
        XCTAssertEqual(sut.undoTitles.count, 1)
        XCTAssertEqual(sut.undoTitles[0].title, "title")
        XCTAssertEqual(sut.undoTitles[0].action, .spam)

        sut.register(handler: handlerMock)
        XCTAssertTrue(sut.undoTitles.isEmpty)
    }

    func testCalculateUndoActionBy() {
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.trash.rawValue), .trash)
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.archive.rawValue), .archive)
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.spam.rawValue), .spam)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.inbox.rawValue), nil)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: ""), nil)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: "test"), .custom("test"))
    }

    func testSendUndoAction() {
        let expectation1 = expectation(description: "Closure called")
        sut = UndoActionManager(apiService: apiServiceMock, fetchEventClosure: {
            expectation1.fulfill()
        })
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("mail/v4/undoactions") {
                completion?(nil, ["Code": 1001], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let testData = UndoTokenData(token: "token", tokenValidTime: 0)
        let expectation2 = expectation(description: "Closure called")
        sut.sendUndoAction(token: testData, completion: { isSuccess in
            XCTAssertTrue(isSuccess)
            expectation2.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
    }
}

