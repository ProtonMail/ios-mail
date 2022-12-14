// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class ComposeViewModelImplTests: XCTestCase {
    private var mockCoreDataService: MockCoreDataContextProvider!
    private var apiMock: APIServiceMock!
    private var message: Message!
    private var testContext: NSManagedObjectContext!
    var fakeUserManager: UserManager!
    var sut: ComposeViewModelImpl!

    override func setUp() {
        super.setUp()

        self.mockCoreDataService = MockCoreDataContextProvider()
        self.apiMock = APIServiceMock()

        testContext = MockCoreDataStore.testPersistentContainer.viewContext
        fakeUserManager = mockUserManager()

        self.message = testContext.performAndWait {
            Message(context: testContext)
        }
        sut = ComposeViewModelImpl(
            msg: message,
            action: .openDraft,
            msgService: fakeUserManager.messageService,
            user: fakeUserManager,
            coreDataContextProvider: mockCoreDataService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockCoreDataService = nil
        self.apiMock = nil
        self.message = nil
        self.testContext = nil

        super.tearDown()
    }

    func testGetAttachment() throws {
        let attachment1 = Attachment(context: testContext)
        attachment1.order = 0
        attachment1.message = message
        let attachment2 = Attachment(context: testContext)
        attachment2.order = 1
        attachment2.message = message
        let attachmentSoftDeleted = Attachment(context: testContext)
        attachmentSoftDeleted.order = 3
        attachmentSoftDeleted.isSoftDeleted = true
        attachmentSoftDeleted.message = message

        let result = try XCTUnwrap(sut.getAttachments())
        for index in result.indices {
            XCTAssertEqual(result[index].order, Int32(index))
        }
    }
}

// MARK: isEmptyDraft tests

// The body decryption part and numAttachment are missing, seems no way to test
private extension ComposeViewModelImplTests {
    func testIsEmptyDraft_messageInit() throws {
        let user = mockUserManager()
        let viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.mockCoreDataService)

        XCTAssertTrue(viewModel.isEmptyDraft())
    }

    func testIsEmptyDraft_subjectField() throws {
        message.title = "abc"
        let user = mockUserManager()
        let viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.mockCoreDataService)

        XCTAssertFalse(viewModel.isEmptyDraft())
    }

    func testIsEmptyDraft_recipientField() throws {
        message.toList = "[]"
        message.ccList = "[]"
        message.bccList = "[]"
        let user = mockUserManager()
        var viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.mockCoreDataService)

        XCTAssertTrue(viewModel.isEmptyDraft())

        message.toList = "eee"
        message.ccList = "abc"
        message.bccList = "fsx"
        viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.mockCoreDataService)
        XCTAssertFalse(viewModel.isEmptyDraft())
    }
}

extension ComposeViewModelImplTests {
    private func mockUserManager(addressID: String = UUID().uuidString) -> UserManager {
        let userInfo = UserInfo.getDefault()
        userInfo.defaultSignature = "Hi"
        let key = Key(keyID: "keyID", privateKey: KeyTestData.privateKey1)
        let address = Address(addressID: addressID,
                              domainID: "",
                              email: "",
                              send: .active,
                              receive: .active,
                              status: .enabled,
                              type: .protonDomain,
                              order: 0,
                              displayName: "the name",
                              signature: "Hello",
                              hasKeys: 1,
                              keys: [key])
        userInfo.set(addresses: [address])
        return UserManager(api: self.apiMock, role: .owner, userInfo: userInfo)
    }
}
