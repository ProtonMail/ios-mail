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
import ProtonCoreCrypto
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations
@testable import ProtonMail
import XCTest

final class ComposerViewControllerTests: XCTestCase {
    var user: UserManager!
    var draft: MessageEntity!
    var nav: UINavigationController!
    var sut: ComposeContainerViewController!

    private var composerViewFactory: ComposerViewFactory!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let contextProviderMock = MockCoreDataContextProvider()
        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { contextProviderMock }

        let apiMock = APIServiceMock()
        user = try UserManager.prepareUser(apiMock: apiMock, globalContainer: globalContainer)

        draft = try prepareEncryptedMessage(
            plaintextBody: MessageDecrypterTestData.decryptedHTMLMimeBody(),
            mimeType: .multipartMixed,
            user: user,
            contextProvider: contextProviderMock
        )

        composerViewFactory = user.container.composerViewFactory
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
            XCTAssertEqual(text, L10n.ScheduledSend.asSchedule)
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
    func testAddImage_imageIsAddedAsInlineImage() throws {
        makeSUTWithNewDraft()
        user.userInfo.maxSpace = Int64.max
        user.userInfo.usedSpace = 0
        loadEditorView()

        // Import image
        let fileName = "\(String.randomString(10)).jpeg"
        let fileURL = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "IMG_0001", withExtension: "JPG"))
        let image = try XCTUnwrap(UIImage(data: try Data(contentsOf: fileURL)))
        let e = expectation(description: "import done")
        sut.fileSuccessfullyImported(as: ConcreteFileData(name: fileName, mimeType: fileName.mimeType(), contents: image)).done { _ in
            e.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
        wait(for: [e])

        wait(
            self.sut.viewModel.childViewModel.composerMessageHelper.draft?.attachments.isEmpty == false
        )
        
        let attachment = try XCTUnwrap(
            sut.viewModel.childViewModel.composerMessageHelper.draft?.attachments.first
        )
        XCTAssertTrue(attachment.isInline)
        XCTAssertEqual(attachment.name, fileName)

        checkInline(shouldExist: true)
    }

    func testAddNoneImageAttachment_addItAsNormalAttachment() throws {
        makeSUTWithNewDraft()
        user.userInfo.maxSpace = Int64.max
        user.userInfo.usedSpace = 0
        loadEditorView()

        // Import image
        let fileName = "\(String.randomString(10)).pdf"
        let fileURL = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "sample", withExtension: "pdf"))
        let data = try Data(contentsOf: fileURL)
        let e = expectation(description: "import done")
        sut.fileSuccessfullyImported(as: ConcreteFileData(name: fileName, mimeType: fileName.mimeType(), contents: data)).done { _ in
            e.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
        wait(for: [e])

        wait(
            self.sut.viewModel.childViewModel.composerMessageHelper.draft?.attachments.isEmpty == false
        )

        let attachment = try XCTUnwrap(
            sut.viewModel.childViewModel.composerMessageHelper.draft?.attachments.first
        )
        XCTAssertFalse(attachment.isInline)
        XCTAssertEqual(attachment.name, fileName)

        checkInline(shouldExist: false, cid: attachment.contentId)
    }
}

extension ComposerViewControllerTests {
    private func loadEditorView() {
        nav.loadViewIfNeeded()
        sut.loadViewIfNeeded()
        sut.header.loadViewIfNeeded()
        sut.editor.loadViewIfNeeded()
        wait(self.sut.editor.htmlEditor.isEditorLoaded == true)
    }

    private func makeSUTWithNewDraft() {
        nav = composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft
        )
        sut = nav.topViewController as? ComposeContainerViewController
    }

    private func makeSUT(originalScheduledTime: Date?) {
        nav = composerViewFactory.makeComposer(
            msg: draft,
            action: .openDraft,
            isEditingScheduleMsg: true,
            originalScheduledTime: originalScheduledTime
        )
        sut = nav.topViewController as? ComposeContainerViewController
    }

    private func checkInline(shouldExist: Bool, cid: String? = nil) {
        let e2 = expectation(description: "Get html body")
        sut.editor.collectDraftDataAndSaveToDB().done { result in
            let hasInline = result?.1.contains(check: "src-original-pm-cid") == true
            if shouldExist {
                XCTAssertTrue(hasInline)
            } else {
                XCTAssertFalse(hasInline)
            }
            if let cid = cid {
                let hasCid = result?.1.contains(check: cid) == true
                if shouldExist {
                    XCTAssertTrue(hasCid)
                } else {
                    XCTAssertFalse(hasCid)
                }
            }
            e2.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }
        wait(for: [e2])
    }

    private func prepareEncryptedMessage(
        plaintextBody: String,
        mimeType: Message.MimeType,
        user: UserManager,
        contextProvider: CoreDataContextProviderProtocol
    ) throws -> MessageEntity {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.userInfo.addressKeys.toArmoredPrivateKeys[0],
            cleartext: plaintextBody
        ).value

        let parsedObject = testMessageDetailData.parseObjectAny()!
        let rawMsg = try contextProvider.performAndWaitOnRootSavingContext(block: { context in
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
        return .init(rawMsg)
    }
}
