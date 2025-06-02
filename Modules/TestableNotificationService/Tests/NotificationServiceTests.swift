// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore
import proton_app_uniffi
import Testing
import UserNotifications

@testable import TestableNotificationService

final class NotificationServiceTests {
    private let userDefaults = TestableUserDefaults.randomInstance()

    private lazy var sut = TestableNotificationService(userDefaults: userDefaults) { [unowned self] _, _ in
        self.stubbedDecryptionResult
    }

    private var stubbedDecryptionResult = DecryptPushNotificationResult.ok(
        .email(
            .init(
                subject: "Decrypted subject",
                sender: .init(name: "John Doe", address: "john.doe@example.com", group: ""),
                messageId: .init(value: ""),
                action: nil
            )
        )
    )

    deinit {
        userDefaults.removePersistentDomain(forName: userDefaults.suiteName)
    }

    @Test
    func whenReplacingTitleAndBodyWithDecryptedInfo_prefersSenderName() async {
        let originalContent = prepareContent()

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.title == "John Doe")
        #expect(updatedContent.body == "Decrypted subject")
    }

    @Test
    func whenReplacingTitleAndBodyWithDecryptedInfo_ifSenderNameIsEmpty_fallsBackToSenderAddress() async {
        let originalContent = prepareContent()

        stubbedDecryptionResult = .ok(
            .email(
                .init(
                    subject: "Decrypted subject",
                    sender: .init(name: "", address: "john.doe@example.com", group: ""),
                    messageId: .init(value: ""),
                    action: nil
                )
            )
        )

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.title == "john.doe@example.com")
        #expect(updatedContent.body == "Decrypted subject")
    }

    @Test
    func whenInitialParsingFails_onlyModifiesTheBody() async {
        let originalContent = prepareContent(userInfo: [:])

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.title == "original title")
        #expect(updatedContent.body == "You received a new message!")
    }

    @Test
    func whenDecryptionFails_onlyModifiesTheBody() async {
        let originalContent = prepareContent()
        let stubbedError = ActionError.other(.unexpected(.crypto))
        stubbedDecryptionResult = .error(stubbedError)

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.title == "original title")
        #expect(updatedContent.body == "You received a new message!")
    }

    // MARK: badge

    @Test
    func whenRecipientIsPrimaryAccount_badgeIsPreserved() async {
        userDefaults[.primaryAccountSessionId] = "123"

        let originalContent = prepareContent()

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.badge == 5)
    }

    @Test(arguments: ["456", nil])
    func whenRecipientIsNotPrimaryAccount_badgeIsStripped(primaryAccountSessionId: String?) async {
        userDefaults[.primaryAccountSessionId] = primaryAccountSessionId

        let originalContent = prepareContent()

        let updatedContent = await sut.transform(originalContent: originalContent)

        #expect(updatedContent.badge == nil)
    }

    private func prepareContent(
        userInfo: [AnyHashable: Any] = ["encryptedMessage": "foo", "UID": "123"]
    ) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "original title"
        content.body = "original body"
        content.badge = 5
        content.userInfo = userInfo
        return content
    }
}
