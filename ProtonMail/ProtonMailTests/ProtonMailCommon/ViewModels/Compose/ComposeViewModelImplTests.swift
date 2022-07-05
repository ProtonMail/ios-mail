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

import ProtonCore_DataModel
import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class ComposeViewModelImplTests: XCTestCase {
    private var coreDataService: CoreDataContextProviderProtocol!
    private var apiMock: APIServiceMock!
    private var message: Message!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.coreDataService = MockCoreDataContextProvider()
        self.apiMock = APIServiceMock()

        let testContext = self.coreDataService.rootSavingContext

        self.message = testContext.performAndWait {
            Message(context: testContext)
        }
    }

    override func tearDownWithError() throws {
        self.coreDataService = nil
        self.apiMock = nil
        self.message = nil

        try super.tearDownWithError()
    }
}

// MARK: isEmptyDraft tests
// The body decryption part and numAttachment are missing, seems no way to test
private extension ComposeViewModelImplTests {
    func testIsEmptyDraft_messageInit() throws {
        let user = mockUserManager()
        let viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.coreDataService)

        XCTAssertTrue(viewModel.isEmptyDraft())
    }

    func testIsEmptyDraft_subjectField() throws {
        message.title = "abc"
        let user = mockUserManager()
        let viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.coreDataService)

        XCTAssertFalse(viewModel.isEmptyDraft())
    }

    func testIsEmptyDraft_recipientField() throws {
        message.toList = "[]"
        message.ccList = "[]"
        message.bccList = "[]"
        let user = mockUserManager()
        var viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.coreDataService)

        XCTAssertTrue(viewModel.isEmptyDraft())

        message.toList = "eee"
        message.ccList = "abc"
        message.bccList = "fsx"
        viewModel = ComposeViewModelImpl(msg: message, action: .openDraft, msgService: user.messageService, user: user, coreDataContextProvider: self.coreDataService)
        XCTAssertFalse(viewModel.isEmptyDraft())
    }
}

extension ComposeViewModelImplTests {
    private func mockUserManager(addressID: String = UUID().uuidString) -> UserManager {
        let userInfo = UserInfo.getDefault()
        userInfo.defaultSignature = "Hi"
        let key = Key(keyID: "keyID", privateKey: KeyTestData.privateKey1.rawValue)
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
