// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
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
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

final class PushNavigationResolverTests: XCTestCase {
    private var sut: PushNavigationResolver!
    private var mockSubscriptionsPack: MockSubscriptionsPackProtocol!

    override func setUp() {
        super.setUp()
        mockSubscriptionsPack = MockSubscriptionsPackProtocol()
        let dependencies = PushNavigationResolver.Dependencies(
            subscriptionsPack: mockSubscriptionsPack
        )
        sut = PushNavigationResolver(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockSubscriptionsPack = nil
        sut = nil
    }

    func testMapNotificationToDeepLink_whenIsRemoteNotification_email() {
        // Not possible yet. Pending to decouple the services dependencies
    }

    func testMapNotificationToDeepLink_whenIsRemoteNotification_openUrl() {
        let expectedUrl = "https://giphy.com"
        let encryptionKitProvider = EncryptionKitProviderMock()
        let uid = encryptionKitProvider.UID
        mockSubscriptionsPack.encryptionKitProvider = encryptionKitProvider

        let encryptedMessage = PushEncryptedMessageTestData
            .openUrlNotification(with: encryptionKitProvider, url: expectedUrl)
        let pnPayload = try! PushNotificationPayload(
            userInfo: ["UID": uid, "encryptedMessage": encryptedMessage!]
        )

        let expectation = expectation(description: "deeplink callback is correct")
        sut.mapNotificationToDeepLink(pnPayload) { deeplink in
            XCTAssert(deeplink != nil)
            XCTAssert(deeplink!.head == DeepLink.Node(name: "toWebBrowser", value: expectedUrl))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testMapNotificationToDeepLink_whenIsLocalNotification_sessionRevoked() {
        let payload = LocalNotificationService.Categories.sessionRevoked.payload()
        let pnPayload = try! PushNotificationPayload(userInfo: payload)

        let expectation = expectation(description: "deeplink callback is correct")
        sut.mapNotificationToDeepLink(pnPayload) { deeplink in
            XCTAssert(deeplink != nil)
            XCTAssert(deeplink!.head == DeepLink.Node(name: "toAccountManager"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testMapNotificationToDeepLink_whenIsLocalNotification_failedToSend() {
        let draftFolderId = 8
        let payload = LocalNotificationService.Categories.failedToSend.payload(with: "dummy_message_id")
        let pnPayload = try! PushNotificationPayload(userInfo: payload)

        let expectation = expectation(description: "deeplink callback is correct")
        sut.mapNotificationToDeepLink(pnPayload) { deeplink in
            XCTAssert(deeplink != nil)
            XCTAssert(deeplink!.head == DeepLink.Node(name: "UserFromNotification", value: nil))
            XCTAssert(deeplink!.head!.next == DeepLink.Node(name: "MailboxViewController", value: "\(draftFolderId)"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
}

private class MockSubscriptionsPackProtocol: SubscriptionsPackProtocol {
    var encryptionKitProvider: EncryptionKitProviderMock? = nil

    func encryptionKit(forUID uid: String) -> EncryptionKit? {
        encryptionKitProvider?.encryptionKit(forSession: uid)
    }
}
