// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations

@testable import ProtonMail
import XCTest

class UndoActionManagerTests: XCTestCase {
    var sut: UndoActionManager!
    var handlerMock: UndoActionHandlerBaseMock!
    var apiServiceMock: APIServiceMock!
    var userManagerMock: UserManager!
    private var testContainer: TestContainer!

    override func setUp() {
        super.setUp()
        handlerMock = UndoActionHandlerBaseMock()
        apiServiceMock = APIServiceMock()
        testContainer = .init()
        userManagerMock = UserManager(api: apiServiceMock, globalContainer: testContainer)

        sut = UndoActionManager(dependencies: userManagerMock.container)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        handlerMock = nil
        apiServiceMock = nil
        userManagerMock = nil
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
        let token = UndoTokenData(token: "token")
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)

        sut.addUndoToken(token, undoActionType: .archive)
        XCTAssertTrue(handlerMock.isShowUndoActionCalled)
        XCTAssertEqual(handlerMock.undoTokens.first, "token")
        XCTAssertEqual(handlerMock.bannerMessage, "title")
    }

    func testAddUndoToken_actionNotMatched() throws {
        let token = UndoTokenData(token: "token")
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)

        sut.addUndoToken(token, undoActionType: .spam)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)
        XCTAssertNil(handlerMock.bannerMessage)
        XCTAssertTrue(handlerMock.undoTokens.isEmpty)
    }

    func testAddUndoToken_tokenReturnAfterThreshold_handlerShouldNotBeCalled() {
        let expectation1 = expectation(description: "wait for threshold")
        let token = UndoTokenData(token: "token")
        sut.register(handler: handlerMock)
        sut.addTitleWithAction(title: "title", action: .archive)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)

        DispatchQueue.global().asyncAfter(deadline: .now() + UndoActionManager.Const.delayThreshold) {
            self.sut.addUndoToken(token, undoActionType: .archive)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: UndoActionManager.Const.delayThreshold + 1, handler: nil)
        XCTAssertFalse(handlerMock.isShowUndoActionCalled)
    }

    func testAddUndoToken_tokenReturnBeforeThreshold_handlerShouldNotBeCalled() {
        let expectation1 = expectation(description: "wait for threshold")
        let token = UndoTokenData(token: "token")
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
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.trash.labelID), .trash)
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.archive.labelID), .archive)
        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.spam.labelID), .spam)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: Message.Location.inbox.labelID), nil)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: ""), nil)

        XCTAssertEqual(sut.calculateUndoActionBy(labelID: "test"), .custom("test"))
    }

    func testRequestUndoAction() {
        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("mail/v4/undoactions") {
                completion(nil, .success(["Code": 1001]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
        let testData = ["token"]
        let expectation2 = expectation(description: "Closure called")
        sut.requestUndoAction(undoTokens: testData, completion: { isSuccess in
            XCTAssertTrue(isSuccess)
            expectation2.fulfill()
        })

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRequestUndoSendAction() {
        let messageID = MessageID.generateLocalID().rawValue
        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("mail/v4/messages/\(messageID)/cancel_send") {
                completion(nil, .success(["Code": 1001]))
            } else if path.contains("/core/v4/events/") || path.contains("/core/v5/events/") {
                completion(nil, .success([
                    "Code": 1000,
                    "EventID": "",
                    "Refresh": 0,
                    "More": 0,
                    "Notices": []
                ]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
        let expectation2 = expectation(description: "api closure called")
        sut.requestUndoSendAction(messageID: MessageID(messageID)) { isSuccess in
            XCTAssertTrue(isSuccess)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testTappingUndoSendBanner_showsComposer() throws {
        let messageID = MessageID.generateLocalID()

        try testContainer.contextProvider.write { context in
            let message = Message(context: context)
            message.messageID = messageID.rawValue
        }

        let undoSendRequest = UndoSendRequest(messageID: messageID)
        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/core/v4/events/") || path.contains("/core/v5/events/") {
                completion(nil, .success([
                    "Code": 1000,
                    "EventID": "",
                    "Refresh": 0,
                    "More": 0,
                    "Notices": []
                ]))
            } else {
                assert(path == undoSendRequest.path)
                completion(nil, .success([:]))
            }
        }

        handlerMock.delaySendSeconds = 3
        sut.register(handler: handlerMock)

        let composerPresentingVC = try XCTUnwrap(handlerMock.composerPresentingVC)
        let window = UIWindow(root: composerPresentingVC, scene: nil)
        window.makeKeyAndVisible()

        sut.showUndoSendBanner(for: messageID)

        waitForDispatchQueueMain()

        let banner = try XCTUnwrap(handlerMock.view.subviews.first as? PMBanner)
        banner.buttonHandler?(banner)

        waitForDispatchQueueMain()

        let presentedVC = try XCTUnwrap(composerPresentingVC.presentedViewController)
        let navigationVC = try XCTUnwrap(presentedVC as? UINavigationController)
        let rootViewController = try XCTUnwrap(navigationVC.viewControllers.first)
        XCTAssert(rootViewController is ComposeContainerViewController)
    }

    private func waitForDispatchQueueMain() {
        let expectation = expectation(description: "wait for DispatchQueue.main")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
