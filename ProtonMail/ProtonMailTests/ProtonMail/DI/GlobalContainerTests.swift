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

import XCTest
@testable import ProtonMail

final class GlobalContainerTests: XCTestCase {
    func testPropertiesThatNeedToBeStateful_whenAccessedButNotStoredElsewhere_arePersistentDuringTheLifetimeOfTheContainer() {
        let sut = GlobalContainer()
        let delegate = MockUnlockManagerDelegate()

        sut.unlockManager.delegate = delegate

        // If the properties weren't retained, they would have been recreated, losing the delegate property
        XCTAssert(sut.unlockManager.delegate === delegate)
    }

    func testRetainCyclesDoNotOccur() {
        var strongRefToContainer: GlobalContainer? = .init()
        weak var weakRefToContainer = strongRefToContainer

        // sourcery:inline:GlobalContainerTests.InitializeAllDependencies
        _ = strongRefToContainer?.appAccessResolver
        _ = strongRefToContainer?.appRatingStatusProvider
        _ = strongRefToContainer?.cachedUserDataProvider
        _ = strongRefToContainer?.contextProvider
        _ = strongRefToContainer?.featureFlagCache
        _ = strongRefToContainer?.internetConnectionStatusProvider
        _ = strongRefToContainer?.keychain
        _ = strongRefToContainer?.keyMaker
        _ = strongRefToContainer?.lastUpdatedStore
        _ = strongRefToContainer?.lockCacheStatus
        _ = strongRefToContainer?.lockPreventor
        _ = strongRefToContainer?.launchService
        _ = strongRefToContainer?.mailEventsPeriodicScheduler
        _ = strongRefToContainer?.notificationCenter
        _ = strongRefToContainer?.pinCodeProtection
        _ = strongRefToContainer?.pinCodeVerifier
        _ = strongRefToContainer?.pushUpdater
        _ = strongRefToContainer?.queueManager
        _ = strongRefToContainer?.resumeAfterUnlock
        _ = strongRefToContainer?.setupCoreDataService
        _ = strongRefToContainer?.unlockManager
        _ = strongRefToContainer?.unlockService
        _ = strongRefToContainer?.userDefaults
        _ = strongRefToContainer?.usersManager
        _ = strongRefToContainer?.userCachedStatus
        _ = strongRefToContainer?.userIntroductionProgressProvider
        _ = strongRefToContainer?.featureFlagsRepository
        _ = strongRefToContainer?.addressBookService
        _ = strongRefToContainer?.backgroundTaskHelper
        _ = strongRefToContainer?.biometricStatusProvider
        _ = strongRefToContainer?.checkProtonServerStatus
        _ = strongRefToContainer?.cleanCache
        _ = strongRefToContainer?.contactPickerModelHelper
        _ = strongRefToContainer?.deviceContacts
        _ = strongRefToContainer?.imageProxyCache
        _ = strongRefToContainer?.mailboxMessageCellHelper
        _ = strongRefToContainer?.pushService
        _ = strongRefToContainer?.saveSwipeActionSetting
        _ = strongRefToContainer?.senderImageCache
        _ = strongRefToContainer?.signInManager
        _ = strongRefToContainer?.storeKitManagerDelegate
        _ = strongRefToContainer?.swipeActionCache
        _ = strongRefToContainer?.urlOpener
        _ = strongRefToContainer?.userNotificationCenter
        // sourcery:end

        strongRefToContainer = nil

        XCTAssertNil(weakRefToContainer)
    }
}
