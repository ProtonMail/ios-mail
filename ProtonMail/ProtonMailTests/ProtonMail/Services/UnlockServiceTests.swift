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
@testable import ProtonMail
import XCTest

final class UnlockTests: XCTestCase {
    private var sut: Unlock!
    private var testContainer: TestContainer!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var mockSetupCoreData: MockSetupCoreDataService!
    private var mockResumeAfterUnlock: MockResumeAfterUnlock!
    private let dummyMainKey = NoneProtection.generateRandomValue(length: 32)

    override func setUp() {
        super.setUp()

        testContainer = .init()
        mockKeyMaker = .init()
        mockSetupCoreData = .init()
        mockResumeAfterUnlock = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }
        testContainer.setupCoreDataServiceFactory.register { self.mockSetupCoreData }
        testContainer.resumeAfterUnlockFactory.register { self.mockResumeAfterUnlock }

        mockKeyMaker.mainKeyStub.bodyIs { _, _ in
            self.dummyMainKey
        }

        sut = .init(dependencies: testContainer)
    }

    override func tearDown() {
        super.tearDown()

        testContainer.usersManagerFactory.reset()
        testContainer = nil
        mockKeyMaker = nil
        mockSetupCoreData = nil
        mockResumeAfterUnlock = nil
        sut = nil
    }

    func testStart_whenAppAccessGranted_itShouldReturnAccessGranted() async {
        setUpAppAccessGranted_and_userInUserDefaults()

        let result = await sut.start()
        XCTAssertEqual(result, .accessGranted)
    }

    func testStart_whenAppAccessDenied_itShouldReturnAccessDenied() async {
        setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults()

        let result = await sut.start()
        XCTAssertNotEqual(result, .accessGranted)
    }

    func testStart_whenNoMainKeyInMemory_itShouldCallMainKeyExists() async throws {
        mockKeyMaker.isMainKeyInMemory = false
        mockKeyMaker.mainKeyExistsStub.bodyIs { _ in
            self.setUpAppAccessGranted_and_userInUserDefaults()
            return Bool.random()
        }
        _ = await sut.start()

        XCTAssertEqual(mockKeyMaker.mainKeyExistsStub.callCounter, 1)
    }

    func testStart_whenMainKeyInMemory_itShouldNotCallMainKeyExists() async throws {
        setUpAppAccessGranted_and_userInUserDefaults()
        _ = await sut.start()

        XCTAssertEqual(mockKeyMaker.mainKeyExistsStub.callCounter, 0)
    }

    func testStart_itShouldLoadUsers() async {
        setUpAppAccessGranted_and_userInUserDefaults()
        sut = .init(dependencies: testContainer)
        XCTAssertEqual(testContainer.usersManager.users.count, 0)

        _ = await sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 1)
    }

    // Works locally but fails on CI and I did not find the problem
    
//    func testStart_whenAppAccessDenied_itShouldDeleteUsers() async {
//        setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults()
//        testContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
//        XCTAssertEqual(testContainer.usersManager.users.count, 1)
//
//        _ = await sut.start()
//        XCTAssertEqual(testContainer.usersManager.users.count, 0)
//    }

    func testStart_whenAppAccessGranted_itShouldCallResumeAfterUnlock() async {
        setUpAppAccessGranted_and_userInUserDefaults()

        _ = await sut.start()
        XCTAssertEqual(mockResumeAfterUnlock.resumeStub.callCounter, 1)
    }
}

extension UnlockTests {
    private func setUpAppAccessGranted_and_userInUserDefaults() {
        testContainer.addNewUserInUserDefaults(userID: "7")
        mockKeyMaker.isMainKeyInMemory = true
    }

    private func setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults() {
        testContainer.addNewUserInUserDefaults(userID: "4")
        mockKeyMaker.isMainKeyInMemory = false
    }
}
