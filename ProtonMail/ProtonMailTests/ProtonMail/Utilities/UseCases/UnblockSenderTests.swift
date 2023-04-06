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

import ProtonCore_DataModel
import XCTest

@testable import ProtonMail

final class UnblockSenderTests: XCTestCase {
    private var incomingDefaultService: MockIncomingDefaultServiceProtocol!
    private var queueManager: MockQueueManagerProtocol!
    private var sut: UnblockSender!

    private let userInfo = UserInfo.dummy

    override func setUpWithError() throws {
        try super.setUpWithError()

        incomingDefaultService = MockIncomingDefaultServiceProtocol()

        queueManager = MockQueueManagerProtocol()

        sut = UnblockSender(
            dependencies: .init(
                incomingDefaultService: incomingDefaultService,
                queueManager: queueManager,
                userInfo: userInfo
            )
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        incomingDefaultService = nil
        queueManager = nil

        try super.tearDownWithError()
    }

    func testExecute_marksLocalDataAsDeletedAndQueuesRemoteAction() throws {
        let emailAddress = String.randomString(10)

        let parameters = UnblockSender.Parameters(emailAddress: emailAddress)
        try sut.execute(parameters: parameters)

        XCTAssertEqual(incomingDefaultService.softDeleteStub.callCounter, 1)
        let softDeletion = try XCTUnwrap(incomingDefaultService.softDeleteStub.lastArguments)
        XCTAssertEqual(softDeletion.a1, .email(emailAddress))

        XCTAssertEqual(queueManager.addTaskStub.callCounter, 1)
        let addedTask = try XCTUnwrap(queueManager.addTaskStub.lastArguments?.a1)
        XCTAssertEqual(addedTask.action, .unblockSender(emailAddress: emailAddress))
    }
}
