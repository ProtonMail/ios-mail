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

    override func setUp() {
        super.setUp()

        self.contextProviderMock = MockCoreDataContextProvider()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        contextProviderMock = nil
    }

    func testToolbarActionTypes_inSpam_containsDelete() {
        makeSUT(labelID: Message.Location.spam.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markAsUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_inTrash_containsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markAsUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_messageIsSpam_containsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markAsUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_messageIsTrash_containsDelete() {
        let label = Label(context: contextProviderMock.mainContext)
        label.labelID = Message.Location.trash.rawValue
        let message = Message(context: contextProviderMock.mainContext)
        message.add(labelID: Message.Location.trash.rawValue)
        makeSUT(labelID: Message.Location.inbox.labelID, message: .init(message))

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markAsUnread,
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
            XCTAssertEqual(result, [.markAsUnread,
                                    .trash,
                                    .moveTo,
                                    .labelAs,
                                    .more])
        }
    }

    private func makeSUT(labelID: LabelID, message: MessageEntity? = nil) {
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        let message = message ?? MessageEntity(Message(context: contextProviderMock.mainContext))

        let factory = SingleMessageViewModelFactory()
        let timeStamp = Date.now.timeIntervalSince1970
        let systemTime = SystemUpTimeMock(localServerTime: timeStamp, localSystemUpTime: 100, systemUpTime: 100)
        sut = factory.createViewModel(labelId: labelID, message: message, user: fakeUser, systemUpTime: systemTime, goToDraft: { _ in })
    }
}
