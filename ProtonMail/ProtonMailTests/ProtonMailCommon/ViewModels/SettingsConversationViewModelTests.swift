// Copyright (c) 2022 Proton Technologies AG
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

class SettingsConversationViewModelTests: XCTestCase {

    var sut: SettingsConversationViewModel!
    var conversationStateProviderMock: MockConversationStateProvider!
    var eventServiceMock: EventsServiceMock!
    var viewModeUpdaterMock: MockViewModeUpdater!

    override func setUp() {
        super.setUp()
        conversationStateProviderMock = MockConversationStateProvider()
        eventServiceMock = EventsServiceMock()
        viewModeUpdaterMock = MockViewModeUpdater()
        sut = SettingsConversationViewModel(
            conversationStateService: self.conversationStateProviderMock,
            updateViewModeService: self.viewModeUpdaterMock,
            eventService: self.eventServiceMock
        )
    }

    override func tearDown() {
        super.tearDown()
        conversationStateProviderMock = nil
        eventServiceMock = nil
        viewModeUpdaterMock = nil
        sut = nil
    }

    func testInit() {
        conversationStateProviderMock.viewMode = .singleMessage

        sut = SettingsConversationViewModel(
            conversationStateService: self.conversationStateProviderMock,
            updateViewModeService: self.viewModeUpdaterMock,
            eventService: self.eventServiceMock
        )
        XCTAssertFalse(sut.isConversationModeEnabled)
        XCTAssertTrue(conversationStateProviderMock.callAdd.wasCalled)
    }

    func testSwitchValueHasChange_success_getConversation() {
        viewModeUpdaterMock.callUpdate.bodyIs { _, _, completion in
            completion?(.success(.conversation))
        }
        eventServiceMock.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, nil, nil)
        }
        let expeaction1 = expectation(description: "Closure is called")

        var isLoadingGetValues: [Bool] = []
        sut.isLoading = { value in
            isLoadingGetValues.append(value)
        }

        sut.switchValueHasChanged(isOn: true) {
            XCTAssertTrue(self.viewModeUpdaterMock.callUpdate.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventServiceMock.callFetchEvents.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.viewModeUpdaterMock.callUpdate.lastArguments)
                XCTAssertEqual(argument.first, .conversation)

                XCTAssertEqual(isLoadingGetValues, [true, false])
                XCTAssertTrue(self.sut.isConversationModeEnabled)
                XCTAssertEqual(self.conversationStateProviderMock.viewMode, .conversation)

                let argument2 = try XCTUnwrap(self.eventServiceMock.callFetchEvents.lastArguments)
                XCTAssertEqual(argument2.a1, Message.Location.allmail.labelID)
            } catch {
                XCTFail("Should not called here")
            }
            expeaction1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSwitchValueHasChange_success_getSingleMessage() {
        viewModeUpdaterMock.callUpdate.bodyIs { _, _, completion in
            completion?(.success(.singleMessage))
        }
        eventServiceMock.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, nil, nil)
        }
        let expeaction1 = expectation(description: "Closure is called")

        var isLoadingGetValues: [Bool] = []
        sut.isLoading = { value in
            isLoadingGetValues.append(value)
        }

        sut.switchValueHasChanged(isOn: false) {
            XCTAssertTrue(self.viewModeUpdaterMock.callUpdate.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventServiceMock.callFetchEvents.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.viewModeUpdaterMock.callUpdate.lastArguments)
                XCTAssertEqual(argument.first, .singleMessage)

                XCTAssertEqual(isLoadingGetValues, [true, false])
                XCTAssertFalse(self.sut.isConversationModeEnabled)
                XCTAssertEqual(self.conversationStateProviderMock.viewMode, .singleMessage)

                let argument2 = try XCTUnwrap(self.eventServiceMock.callFetchEvents.lastArguments)
                XCTAssertEqual(argument2.a1, Message.Location.allmail.labelID)
            } catch {
                XCTFail("Should not called here")
            }
            expeaction1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSwitchValueHasChange_failToUpdate() {
        viewModeUpdaterMock.callUpdate.bodyIs { _, _, completion in
            completion?(.failure(NSError.init(domain: "", code: 0, userInfo: nil)))
        }

        let expeaction1 = expectation(description: "Closure is called")

        var errorGetInRequestFailed: NSError?
        sut.requestFailed = { value in
            errorGetInRequestFailed = value
        }
        var valueGetInViewModeHasChanged: Bool?
        sut.conversationViewModeHasChanged = { value in
            valueGetInViewModeHasChanged = value
        }

        sut.switchValueHasChanged(isOn: false) {
            XCTAssertTrue(self.viewModeUpdaterMock.callUpdate.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.viewModeUpdaterMock.callUpdate.lastArguments)
                XCTAssertEqual(argument.first, .singleMessage)

                XCTAssertFalse(self.sut.isConversationModeEnabled)
                XCTAssertEqual(self.conversationStateProviderMock.viewMode, .singleMessage)

                XCTAssertNotNil(errorGetInRequestFailed)
                XCTAssertEqual(valueGetInViewModeHasChanged, self.sut.isConversationModeEnabled)
            } catch {
                XCTFail("Should not called here")
            }
            expeaction1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testViewModeHasChanged() {
        var countOfClosureIsCalled = 0
        var valueGetFromViewModeHasChanged: Bool?
        sut.conversationViewModeHasChanged = { value in
            valueGetFromViewModeHasChanged = value
            countOfClosureIsCalled += 1
        }
        sut.viewModeHasChanged(viewMode: .singleMessage)
        XCTAssertFalse(sut.isConversationModeEnabled)
        XCTAssertEqual(valueGetFromViewModeHasChanged, false)

        sut.viewModeHasChanged(viewMode: .conversation)
        XCTAssertTrue(sut.isConversationModeEnabled)
        XCTAssertEqual(valueGetFromViewModeHasChanged, true)

        XCTAssertEqual(countOfClosureIsCalled, 2)
    }
}
