// Copyright (c) 2024 Proton Technologies AG
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

@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

final class AutoImportContactsFeatureTests: XCTestCase {
    private var sut: AutoImportContactsFeature!
    private var testContainer: TestContainer!
    private var mockContactsSyncQueue: MockContactsSyncQueueProtocol!

    override func setUp() {
        super.setUp()
        mockContactsSyncQueue = .init()

        testContainer = .init()
        let mockUserManager = UserManager(api: APIServiceMock(), userID: "dummyUserID", globalContainer: testContainer)
        testContainer.usersManager.add(newUser: mockUserManager)
        mockUserManager.container.contactSyncQueueFactory.register {
            self.mockContactsSyncQueue
        }

        sut = AutoImportContactsFeature(dependencies: mockUserManager.container)
    }

    override func tearDown() {
        mockContactsSyncQueue = nil
        testContainer = nil
        sut = nil
        super.tearDown()
    }

    func testDisableSettingForUser_itTriggersCancelTaskNotification() {
        let cancelImportContactsTaskExpectation = XCTNSNotificationExpectation(
            name: .cancelImportContactsTask,
            object: nil,
            notificationCenter: testContainer.notificationCenter
        )
        sut.disableSettingForUser()
        wait(for: [cancelImportContactsTaskExpectation], timeout: 2)
    }

    func testOnProtonStorageExceeded_whenEventReceived_itShouldDisableFeature() {
        sut.enableSettingForUser()
        XCTAssertTrue(sut.isSettingEnabledForUser)

        mockContactsSyncQueue._protonStorageQuotaExceeded.send()

        XCTAssertFalse(sut.isSettingEnabledForUser)
    }

    func testOnProtonStorageExceeded_whenEventReceived_itShouldDeleteTheContactsQueue() {
        mockContactsSyncQueue._protonStorageQuotaExceeded.send()
        XCTAssertTrue(mockContactsSyncQueue.deleteQueueStub.wasCalled)
    }
}
