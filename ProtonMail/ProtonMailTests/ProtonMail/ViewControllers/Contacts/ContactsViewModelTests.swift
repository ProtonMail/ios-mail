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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class ContactsViewModelTests: XCTestCase {
    var testContainer: TestContainer!
    var sut: ContactsViewModel!
    var user: UserManager!

    override func setUpWithError() throws {
        testContainer = .init()
        user = try UserManager.prepareUser(apiMock: .init(), globalContainer: testContainer)
        testContainer.usersManager.add(newUser: user)
        sut = ContactsViewModel(dependencies: user.container)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        user = nil
        testContainer = nil
    }

    func testShowContactAutoSyncBanner_autoImportIsEnabled_returnFalse() {
        user.container.autoImportContactsFeature.enableSettingForUser()

        XCTAssertFalse(sut.showShowContactAutoSyncBanner())
    }

    func testShowContactAutoSyncBanner_autoImportIsDisabled_flagInUserDefaultIsFalse_returnTrue() {
        testContainer.userDefaults[.hasContactAutoSyncBannerShown] = false
        user.container.autoImportContactsFeature.disableSettingAndDeleteQueueForUser()

        XCTAssertTrue(sut.showShowContactAutoSyncBanner())
    }

    func testShowContactAutoSyncBanner_autoImportIsDisabled_flagInUserDefaultIsTrue_returnFalse() {
        testContainer.userDefaults[.hasContactAutoSyncBannerShown] = true
        user.container.autoImportContactsFeature.disableSettingAndDeleteQueueForUser()

        XCTAssertFalse(sut.showShowContactAutoSyncBanner())
    }

    func testMarkAutoContactSyncAsSeen_flagInUserDefaultIsSetToTrue() {
        XCTAssertFalse(testContainer.userDefaults[.hasContactAutoSyncBannerShown])
        sut.markAutoContactSyncAsSeen()

        XCTAssertTrue(testContainer.userDefaults[.hasContactAutoSyncBannerShown])
    }

    func testEnableAutoContactSync_featureIsEnabled() {
        sut.enableAutoContactSync()

        XCTAssertTrue(user.container.autoImportContactsFeature.isSettingEnabledForUser)
        XCTAssertTrue(testContainer.userDefaults[.hasContactAutoSyncBannerShown])
    }
}
