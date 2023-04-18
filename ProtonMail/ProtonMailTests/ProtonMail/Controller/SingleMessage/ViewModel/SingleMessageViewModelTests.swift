// Copyright (c) 2022 Proton AG
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

import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class SingleMessageViewModelTests: XCTestCase {
    var contextProviderMock: MockCoreDataContextProvider!
    var sut: SingleMessageViewModel!
    var toolbarProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var toolbarCustomizeSpotlightStatusProvider: MockToolbarCustomizeSpotlightStatusProvider!
    var userIntroductionProgressProviderMock: MockUserIntroductionProgressProvider!
    var toolbarCustomizationInfoBubbleViewStatusProvider: MockToolbarCustomizationInfoBubbleViewStatusProvider!
    var nextMessageAfterMoveStatusProviderMock: MockNextMessageAfterMoveStatusProvider!
    var coordinatorMock: SingleMessageCoordinator!
    var notificationCenterMock: NotificationCenter!
    var mockSenderImageStatusProvider: MockSenderImageStatusProvider!

    override func setUp() {
        super.setUp()
        toolbarProviderMock = MockToolbarActionProvider()
        contextProviderMock = MockCoreDataContextProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        toolbarCustomizeSpotlightStatusProvider = MockToolbarCustomizeSpotlightStatusProvider()
        userIntroductionProgressProviderMock = MockUserIntroductionProgressProvider()
        toolbarCustomizationInfoBubbleViewStatusProvider = MockToolbarCustomizationInfoBubbleViewStatusProvider()
        nextMessageAfterMoveStatusProviderMock = .init()
        notificationCenterMock = .init()
        mockSenderImageStatusProvider = .init()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        contextProviderMock = nil
        toolbarProviderMock = nil
        saveToolbarActionUseCaseMock = nil
        toolbarCustomizeSpotlightStatusProvider = nil
        toolbarCustomizationInfoBubbleViewStatusProvider = nil
        notificationCenterMock = nil
        mockSenderImageStatusProvider = nil
    }

    func testToolbarActionTypes_inSpam_containsDelete() {
        makeSUT(labelID: Message.Location.spam.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_inTrash_containsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_messageIsSpam_containsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_messageIsTrash_containsDelete() {
        let label = Label(context: contextProviderMock.viewContext)
        label.labelID = Message.Location.trash.rawValue
        let message = Message(context: contextProviderMock.viewContext)
        message.unRead = false
        message.add(labelID: Message.Location.trash.rawValue)
        makeSUT(labelID: Message.Location.inbox.labelID, message: .init(message))

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_notInSpamAndTrash_containsTrash() {
        let locations = Message.Location.allCases.filter { $0 != .spam && $0 != .trash }

        for location in locations {
            makeSUT(labelID: location.labelID)
            let result = sut.toolbarActionTypes()
            XCTAssertEqual(result, [.markUnread,
                                    .trash,
                                    .moveTo,
                                    .labelAs,
                                    .more])
        }
    }

    func testToolbarActionTypes_withCustomToolbarActions() {
        makeSUT(labelID: "0")
        toolbarProviderMock.messageToolbarActions = [.star, .saveAsPDF]

        let result = sut.toolbarActionTypes()

        XCTAssertEqual(result, [
            .star,
            .saveAsPDF,
            .more
        ])
    }

    func testToolbarActionTypes_withScheduleSendMsg_notContainsReplyForwardActions() {
        var flags = MessageFlag()
        flags.insert(.scheduledSend)
        let msg = MessageEntity.make(rawFlag: flags.rawValue)
        toolbarProviderMock.messageToolbarActions = [.reply, .forward]
        makeSUT(labelID: Message.Location.inbox.labelID, message: msg)


        let result = sut.toolbarActionTypes()

        XCTAssertFalse(result.contains(.reply))
        XCTAssertFalse(result.contains(.forward))
        XCTAssertFalse(result.contains(.replyInConversation))
        XCTAssertFalse(result.contains(.forwardInConversation))
        XCTAssertFalse(result.contains(.replyOrReplyAll))
    }

    func testToolbarCustomizationAllAvailableActions_sameAsActionInActionSheet() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        let bodyViewModel = sut.contentViewModel.messageBodyViewModel
        let bodyInfo = sut.contentViewModel.messageInfoProvider
        var expected = MessageViewActionSheetViewModel(title: sut.message.title,
                                                       labelID: sut.labelId,
                                                       isStarred: sut.message.isStarred,
                                                       isBodyDecryptable: bodyInfo.isBodyDecryptable,
                                                       messageRenderStyle: bodyViewModel.currentMessageRenderStyle,
                                                       shouldShowRenderModeOption: bodyInfo.shouldDisplayRenderModeOptions,
                                                       isScheduledSend: bodyInfo.message.isScheduledSend).items
        expected = expected.filter({ $0 != .reply && $0 != .replyAll })
        expected.insert(.reply, at: 0)

        XCTAssertEqual(sut.toolbarCustomizationAllAvailableActions(), expected)
    }

    func testUpdateToolbarActions_updateActionWithoutMoreAction() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])
    }

    func testUpdateToolbarActions_updateActionWithMoreAction() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead, .more]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])

        let e1 = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.more, .unstar, .markRead]) { _ in
            e1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalled)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])
    }

    func testShouldShowToolbarCustomizeSpotlight_userHasNotSeenSpotlight_returnTrue() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userIntroductionProgressProviderMock.shouldShowSpotlightStub.bodyIs { _, key, _ in
            XCTAssertEqual(key, .toolbarCustomization)
            return true
        }

        XCTAssertTrue(sut.shouldShowToolbarCustomizeSpotlight())
    }

    func testShouldShowToolbarCustomizeSpotlight_userHasSeenSpotlight_returnFalse() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userIntroductionProgressProviderMock.shouldShowSpotlightStub.bodyIs { _, key, _ in
            XCTAssertEqual(key, .toolbarCustomization)
            return false
        }

        XCTAssertFalse(sut.shouldShowToolbarCustomizeSpotlight())
    }

    func testNavigateToNextMessage_withFlagIsFalse_coordinatorShouldNotBeCalled() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        e.isInverted = true
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = false

        sut.navigateToNextMessage(isInPageView: true)

        wait(for: [e], timeout: 2)
    }

    func testNavigateToNextMessage_withFlagIsTrue_coordinatorIsCalled() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true

        sut.navigateToNextMessage(isInPageView: true)

        wait(for: [e], timeout: 2)
    }

    private func makeSUT(labelID: LabelID, message: MessageEntity? = nil) {
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        let messageObject = Message(context: contextProviderMock.viewContext)
        messageObject.unRead = false
        let message = message ?? MessageEntity(messageObject)

        let timeStamp = Date.now.timeIntervalSince1970
        let systemTime = SystemUpTimeMock(localServerTime: timeStamp, localSystemUpTime: 100, systemUpTime: 100)

        let components = SingleMessageComponentsFactory()

        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                spamType: .none,
                user: fakeUser,
                imageProxy: .init(dependencies: .init(apiService: apiMock))
            ),
            bannerViewModel: components.banner(labelId: labelID, message: message, user: fakeUser),
            attachments: .init()
        )

        coordinatorMock = SingleMessageCoordinator(navigationController: UINavigationController(),
                                                   labelId: labelID,
                                                   message: message,
                                                   user: fakeUser,
                                                   infoBubbleViewStatusProvider: toolbarCustomizationInfoBubbleViewStatusProvider)

        sut = .init(
            labelId: labelID,
            message: message,
            user: fakeUser,
            imageProxy: .init(dependencies: .init(apiService: apiMock)),
            childViewModels: childViewModels,
            internetStatusProvider: InternetConnectionStatusProvider(),
            userIntroductionProgressProvider: userIntroductionProgressProviderMock,
            saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
            toolbarActionProvider: toolbarProviderMock,
            toolbarCustomizeSpotlightStatusProvider: toolbarCustomizeSpotlightStatusProvider,
            systemUpTime: systemTime,
            coordinator: coordinatorMock,
            nextMessageAfterMoveStatusProvider: nextMessageAfterMoveStatusProviderMock,
            dependencies: components.contentViewModelDependencies(user: fakeUser, senderImageStatusProvider: mockSenderImageStatusProvider),
            goToDraft: { _, _ in },
            notificationCenter: notificationCenterMock
        )
    }
}
