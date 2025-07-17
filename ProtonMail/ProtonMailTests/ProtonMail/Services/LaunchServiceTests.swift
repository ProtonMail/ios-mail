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

import Foundation

import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class LaunchTests: XCTestCase {
    private var sut: Launch!
    private var testContainer: TestContainer!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var mockSetupCoreData: MockSetupCoreDataService!
    private let dummyMainKey = NoneProtection.generateRandomValue(length: 32)

    override func setUp() {
        super.setUp()

        testContainer = .init()
        mockKeyMaker = .init()
        mockSetupCoreData = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }
        testContainer.setupCoreDataServiceFactory.register { self.mockSetupCoreData }

        mockKeyMaker.mainKeyStub.bodyIs { _, _ in
            self.dummyMainKey
        }

        sut = .init(dependencies: testContainer)
    }

    override func tearDown() {
        super.tearDown()

        testContainer = nil
        mockKeyMaker = nil
        mockSetupCoreData = nil
        sut = nil
    }

    func testStart_itShouldCallMainKeyExists() throws {
        try sut.start()
        XCTAssertTrue(mockKeyMaker.mainKeyExistsStub.wasCalledExactlyOnce)
    }

    func testStart_itShouldCallSetupCoreData() throws {
        try sut.start()
        XCTAssertTrue(mockSetupCoreData.setupStub.wasCalledExactlyOnce)
    }

    func testStart_whenCoreDataSetupFails_itShouldNotLoadUsers() {
        mockSetupCoreData.setupStub.bodyIs { _ in
            throw NSError(domain: "", code: 0)
        }
        setUpAppAccessGranted_and_userInUserDefaults()

        try? sut.start()
        XCTAssertTrue(mockSetupCoreData.setupStub.wasCalledExactlyOnce)
        XCTAssertEqual(testContainer.usersManager.users.count, 0)
    }

    func testStart_whenAccessGranted_itShouldLoadUsersIntoMemory() throws {
        setUpAppAccessGranted_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 1)
    }

    func testStart_whenAccessDenied_itShouldNotLoadUsersIntoMemory() throws {
        setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 0)
    }

    func testLoadUserDataAfterUnlock_itShouldLoadUsersIntoMemory() throws {
        setUpAppAccessGranted_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 1)
    }
}

extension LaunchTests {

    private func setUpAppAccessGranted_and_userInUserDefaults() {
        testContainer.addNewUserInUserDefaults(userID: "7")
        mockKeyMaker.isMainKeyInMemory = true
    }

    private func setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults() {
        testContainer.addNewUserInUserDefaults(userID: "4")
        mockKeyMaker.isMainKeyInMemory = false
    }
}
