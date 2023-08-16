// Copyright (c) 2023 Proton Technologies AG
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

import Groot
import ProtonCore_Crypto
import ProtonCore_TestingToolkit
import ProtonCore_UIFoundations
@testable import ProtonMail
import XCTest

final class ComposerViewControllerTests: XCTestCase {
    var user: UserManager!
    var draft: Message!
    var nav: UINavigationController!
    var sut: ComposeContainerViewController!

    private var composerViewFactory: ComposerViewFactory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let apiMock = APIServiceMock()
        user = try UserManager.prepareUser(apiMock: apiMock)
        let contextProviderMock = MockCoreDataContextProvider()

        draft = try prepareEncryptedMessage(
            plaintextBody: MessageDecrypterTestData.decryptedHTMLMimeBody(),
            mimeType: .multipartMixed,
            user: user,
            contextProvider: contextProviderMock
        )

        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { contextProviderMock }
        let userContainer = UserContainer(userManager: user, globalContainer: globalContainer)

        composerViewFactory = userContainer.composerViewFactory
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        composerViewFactory = nil
        nav = nil
        draft = nil
        user = nil
    }

    func testEditorOpenScheduleSendActionSheet_whenScheduledTime_withOriginalScheduledTime_itShouldShowScheduleAsOption() {
        makeSUT(originalScheduledTime: .init(Date()))
        nav.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        sut.editor.openScheduleSendActionSheet?()

        let actionSheet = nav.view.subviews.compactMap { $0 as? PMActionSheet }.first
        XCTAssertEqual(actionSheet?.itemGroups.first?.items.count, 4)
        let item = actionSheet?.itemGroups.first?.items.first?.components.first as? PMActionSheetTextComponent
        switch item!.text {
        case .left(let text):
            XCTAssertEqual(text, L11n.ScheduledSend.asSchedule)
        default:
            XCTFail()
        }
    }

    func testEditorOpenScheduleSendActionSheet_whenScheduledTime_itShouldShowThreeOptions() {
        makeSUT(originalScheduledTime: nil)
        nav.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        sut.editor.openScheduleSendActionSheet?()

        let actionSheet = nav.view.subviews.compactMap { $0 as? PMActionSheet }.first
        XCTAssertEqual(actionSheet?.itemGroups.first?.items.count, 3)
    }
}

extension ComposerViewControllerTests {
    private func makeSUT(originalScheduledTime: Date?) {
        nav = composerViewFactory.makeComposer(
            msg: draft,
            action: .openDraft,
            isEditingScheduleMsg: true,
            originalScheduledTime: originalScheduledTime
        )
        sut = nav.topViewController as? ComposeContainerViewController
    }

    private func prepareEncryptedMessage(
        plaintextBody: String,
        mimeType: Message.MimeType,
        user: UserManager,
        contextProvider: CoreDataContextProviderProtocol
    ) throws -> Message {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.userInfo.addressKeys.toArmoredPrivateKeys[0],
            cleartext: plaintextBody
        ).value

        let parsedObject = testMessageDetailData.parseObjectAny()!
        return try contextProvider.performAndWaitOnRootSavingContext(block: { context in
            let messageObject = try XCTUnwrap(
                GRTJSONSerialization.object(
                    withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: context
                ) as? Message
            )
            messageObject.userID = user.userID.rawValue
            messageObject.isDetailDownloaded = true
            messageObject.body = encryptedBody
            messageObject.mimeType = mimeType.rawValue
            return messageObject
        })
    }
}
