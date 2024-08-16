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

import ProtonCorePayments
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
@testable import ProtonMail

final class UserContainerTests: XCTestCase {

    func testPropertiesThatNeedToBeStateful_whenAccessedButNotStoredElsewhere_arePersistentDuringTheLifetimeOfTheContainer() {
        class MockDelegate: MockBlockedSenderCacheUpdaterDelegate & StoreKitManagerDelegate {
            let tokenStorage: PaymentTokenStorage? = nil
            let isUnlocked = false
            let isSignedIn = false
            let activeUsername: String? = nil
            let userId: String? = nil
        }

        let user = UserManager(api: APIServiceMock())
        let sut = user.container
        let delegate = MockDelegate()

        sut.blockedSenderCacheUpdater.delegate = delegate
        sut.payments.storeKitManager.delegate = delegate

        // If the properties weren't retained, they would have been recreated, losing the delegate property
        XCTAssert(sut.blockedSenderCacheUpdater.delegate === delegate)
        XCTAssert(sut.payments.storeKitManager.delegate === delegate)
    }

    func testRetainCyclesDoNotOccur() {
        let globalContainer = GlobalContainer()

        var strongRefToUser: UserManager? = UserManager(
            api: APIServiceMock(),
            userID: "foo",
            globalContainer: globalContainer
        )
        var strongRefToContainer: UserContainer? = strongRefToUser?.container

        weak var weakRefToUser = strongRefToUser
        weak var weakRefToContainer = strongRefToContainer

        // undo a side-effect of UserManager.init
        globalContainer.queueManager.unregisterHandler(for: "foo", completion: nil)
        _ = globalContainer.queueManager.queuedMessageIds()

        // sourcery:inline:UserContainerTests.InitializeAllDependencies
        _ = strongRefToContainer?.apiService
        _ = strongRefToContainer?.autoImportContactsFeature
        _ = strongRefToContainer?.cacheService
        _ = strongRefToContainer?.contactSyncQueue
        _ = strongRefToContainer?.composerViewFactory
        _ = strongRefToContainer?.contactService
        _ = strongRefToContainer?.contactGroupService
        _ = strongRefToContainer?.conversationService
        _ = strongRefToContainer?.conversationStateService
        _ = strongRefToContainer?.eventProcessor
        _ = strongRefToContainer?.eventsService
        _ = strongRefToContainer?.featureFlagsDownloadService
        _ = strongRefToContainer?.featureFlagProvider
        _ = strongRefToContainer?.fetchAndVerifyContacts
        _ = strongRefToContainer?.fetchAttachment
        _ = strongRefToContainer?.fetchAttachmentMetadata
        _ = strongRefToContainer?.fetchEmailAddressesPublicKey
        _ = strongRefToContainer?.fetchMessageDetail
        _ = strongRefToContainer?.fetchMessageMetaData
        _ = strongRefToContainer?.imageProxy
        _ = strongRefToContainer?.incomingDefaultService
        _ = strongRefToContainer?.labelService
        _ = strongRefToContainer?.localNotificationService
        _ = strongRefToContainer?.messageService
        _ = strongRefToContainer?.queueHandler
        _ = strongRefToContainer?.telemetryService
        _ = strongRefToContainer?.undoActionManager
        _ = strongRefToContainer?.userService
        _ = strongRefToContainer?.user
        _ = strongRefToContainer?.answerInvitation
        _ = strongRefToContainer?.appRatingService
        _ = strongRefToContainer?.blockedSenderCacheUpdater
        _ = strongRefToContainer?.cleanUserLocalMessages
        _ = strongRefToContainer?.emailAddressStorage
        _ = strongRefToContainer?.reportService
        _ = strongRefToContainer?.contactViewsFactory
        _ = strongRefToContainer?.extractBasicEventInfo
        _ = strongRefToContainer?.fetchEventDetails
        _ = strongRefToContainer?.fetchMessages
        _ = strongRefToContainer?.fetchSenderImage
        _ = strongRefToContainer?.importDeviceContacts
        _ = strongRefToContainer?.messageSearch
        _ = strongRefToContainer?.nextMessageAfterMoveStatusProvider
        _ = strongRefToContainer?.onboardingUpsellPageFactory
        _ = strongRefToContainer?.payments
        _ = strongRefToContainer?.paymentsUIFactory
        _ = strongRefToContainer?.planService
        _ = strongRefToContainer?.purchaseManager
        _ = strongRefToContainer?.purchasePlan
        _ = strongRefToContainer?.settingsViewsFactory
        _ = strongRefToContainer?.saveToolbarActionSettings
        _ = strongRefToContainer?.sendBugReport
        _ = strongRefToContainer?.storeKitManager
        _ = strongRefToContainer?.toolbarActionProvider
        _ = strongRefToContainer?.toolbarSettingViewFactory
        _ = strongRefToContainer?.unblockSender
        _ = strongRefToContainer?.updateMailbox
        _ = strongRefToContainer?.upsellButtonStateProvider
        _ = strongRefToContainer?.upsellPageFactory
        _ = strongRefToContainer?.upsellOfferProvider
        _ = strongRefToContainer?.upsellTelemetryReporter
        // sourcery:end

        strongRefToUser = nil
        strongRefToContainer = nil

        XCTAssertNil(weakRefToUser)
        XCTAssertNil(weakRefToContainer)
    }
}
