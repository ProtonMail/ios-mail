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

@testable import ProtonMail
import ProtonCoreCrypto
import XCTest

final class PushNavigationResolverTests: XCTestCase {
    typealias InMemorySaver = PushNotificationServiceTests.InMemorySaver

    private var sut: PushNavigationResolver!
    private var mockPushDecryptionKeysProvider: MockPushDecryptionKeysProvider!
    private var mockKitSaver: InMemorySaver<Set<PushSubscriptionSettings>>!
    private var mockFailedPushMarker: MockFailedPushDecryptionMarker!

    private let dummyUID = UUID().uuidString
    private let dummyKeyPair = DummyKeyPair()

    override func setUp() {
        super.setUp()
        mockPushDecryptionKeysProvider = .init()
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = [
            DecryptionKey(
                privateKey: ArmoredKey(value: dummyKeyPair.privateKey),
                passphrase: Passphrase(value: dummyKeyPair.passphrase)
            )
        ]
        mockKitSaver = .init()
        mockFailedPushMarker = .init()
        let dependencies: PushNavigationResolver.Dependencies = .init(
            decryptionKeysProvider: mockPushDecryptionKeysProvider,
            oldEncryptionKitSaver: mockKitSaver,
            failedPushDecryptionMarker: mockFailedPushMarker
        )
        sut = PushNavigationResolver(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockPushDecryptionKeysProvider = nil
        mockKitSaver = nil
        mockFailedPushMarker = nil
        sut = nil
    }

    func testMapNotificationToDeepLink_whenIsRemoteNotification_email() {
        // Not possible yet. Pending to decouple the services dependencies
    }

    func testMapNotificationToDeepLink_whenIsRemoteNotification_openUrl() {
        let expectedUrl = "https://giphy.com"
        let encryptedMessage = PushEncryptedMessageTestData
            .openUrlNotification(with: dummyKeyPair, url: expectedUrl)
        let pnPayload = try! PushNotificationPayload(
            userInfo: ["UID": dummyUID, "encryptedMessage": encryptedMessage!]
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

    func testMapNotificationToDeepLink_whenFailsToDecrypt_shouldMarkDecryptionFailed() {
        let encryptedMessage = PushEncryptedMessageTestData
            .openUrlNotification(with: dummyKeyPair, url: "https://giphy.com")
        let pnPayload = try! PushNotificationPayload(
            userInfo: ["UID": dummyUID, "encryptedMessage": encryptedMessage!]
        )
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = []

        let expectation = expectation(description: "deeplink callback is correct")
        sut.mapNotificationToDeepLink(pnPayload) { deeplink in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(mockFailedPushMarker.markPushNotificationDecryptionFailureStub.callCounter, 1)
    }

    /// This test checks that stored encryption kits before the push encryption refactor are also used to decrypt pushes
    func testMapNotificationToDeepLink_whenKeyInOldEncryptionKitSaver_shouldProperlyDecryptNotification() {
        let expectedUrl = "https://giphy.com"
        let encryptedMessage = PushEncryptedMessageTestData
            .openUrlNotification(with: dummyKeyPair, url: expectedUrl)
        let pnPayload = try! PushNotificationPayload(
            userInfo: ["UID": dummyUID, "encryptedMessage": encryptedMessage!]
        )

        var pushSubscriptionSetting = PushSubscriptionSettings(token: "", UID: dummyUID)
        pushSubscriptionSetting.encryptionKit = .init(
            passphrase: dummyKeyPair.passphrase,
            privateKey: dummyKeyPair.privateKey,
            publicKey: dummyKeyPair.publicKey.value
        )
        mockKitSaver.set(newValue: Set([pushSubscriptionSetting]))
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = []

        let expectation = expectation(description: "deeplink callback is correct")
        sut.mapNotificationToDeepLink(pnPayload) { deeplink in
            XCTAssert(deeplink != nil)
            XCTAssert(deeplink!.head == DeepLink.Node(name: "toWebBrowser", value: expectedUrl))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
}
