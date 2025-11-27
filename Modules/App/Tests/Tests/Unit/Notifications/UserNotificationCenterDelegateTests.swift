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

import Combine
import InboxTesting
import Testing
import UIKit
import proton_app_uniffi

@testable import ProtonMail

@MainActor
@Suite(.serialized)
final class UserNotificationCenterDelegateTests {
    private let mailSession: MailSessionSpy
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(.noSession)
    private let urlOpener = URLOpenerSpy()
    private let userNotificationCenter = UserNotificationCenterSpy()

    private lazy var sut = UserNotificationCenterDelegate(
        sessionStatePublisher: sessionStateSubject.eraseToAnyPublisher(),
        urlOpener: urlOpener,
        userNotificationCenter: userNotificationCenter,
        getMailSession: { [unowned self] in mailSession }
    )

    private let testURL = URL(string: "https://example.com")!

    init() {
        let mailSession = MailSessionSpy()

        mailSession.storedSessions = [
            .init(id: "session-1", userId: "user-1", state: .authenticated),
            .init(id: "session-2", userId: "user-2", state: .authenticated),
        ]

        self.mailSession = mailSession

        mailSession.onPrimaryAccountChanged = { [unowned self] userId in
            let sessionAssociatedWithUserId = mailSession.storedSessions.first { $0.userId() == userId }!

            sessionStateSubject.send(
                .activeSession(session: MailUserSessionSpy(id: sessionAssociatedWithUserId.sessionId()))
            )
        }
    }

    deinit {
        mailSession.onPrimaryAccountChanged = nil
    }

    @MainActor @Test
    func whenServicesAreSetUp_assignsItselfAsUserNotificationCenterDelegate() {
        sut.setUpService()

        #expect(userNotificationCenter.delegate === sut)
    }

    @Test
    func whenServicesAreSetUp_registersNotificationActions() throws {
        sut.setUpService()

        let registeredCategory = try #require(userNotificationCenter.setNotificationCategoriesInvocations.first?.first)
        #expect(registeredCategory.identifier == "message_created")
        #expect(registeredCategory.actions.count == NotificationQuickAction.allCases.count)
    }

    @Test
    func whenNotificationIsReceivedInForeground_presentsItWithBannerAndSound() async {
        let notification = UNNotificationResponseStubFactory.makeNotification(content: .init())

        let options = await sut.userNotificationCenter(.current(), willPresent: notification)

        #expect(options == [.banner, .list, .sound])
    }

    @Test
    func givenMessageTypeNotification_whenUserOpensIt_switchesThePrimaryAccount() async throws {
        let response = makeNotificationResponse(type: .newMessage(sessionId: "session-2", remoteId: .init(value: "")), action: nil)

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.setPrimaryAccountInvocations == ["user-2"])
    }

    @Test
    func givenMessageTypeNotification_whenUserOpensIt_navigatesToMessageThroughDeepLink() async {
        let response = makeNotificationResponse(
            type: .newMessage(sessionId: "session-1", remoteId: .init(value: "foo")),
            body: "Message subject",
            action: nil
        )

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(urlOpener.openURLInvocations == [URL(string: "protonmail://messages/foo?subject=Message%20subject")!])
    }

    @Test
    func givenMessageTypeNotification_whenUserSelectsAnAction_executesTheAction() async throws {
        let remoteId = RemoteId(value: "foo")

        let response = makeNotificationResponse(
            type: .newMessage(sessionId: "session-1", remoteId: remoteId),
            body: "Message subject",
            action: .markAsRead
        )

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.executeNotificationQuickActionInvocations.count == 1)

        let invocation = try #require(mailSession.executeNotificationQuickActionInvocations.first)
        #expect(invocation.0.sessionId() == "session-1")
        #expect(invocation.1 == .markAsRead(remoteId: remoteId))
    }

    @Test
    func givenMessageTypeNotification_whenUserSelectsAnAction_decrementsBadgeCount() async throws {
        try await UNUserNotificationCenter.current().setBadgeCount(5)

        let remoteId = RemoteId(value: "foo")

        let response = makeNotificationResponse(
            type: .newMessage(sessionId: "session-1", remoteId: remoteId),
            body: "Message subject",
            action: .markAsRead
        )

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(UIApplication.shared.applicationIconBadgeNumber == 4)
    }

    @Test
    func givenMessageTypeNotification_whenUserSelectsAnAction_doesntDoAnythingElse() async {
        let response = makeNotificationResponse(
            type: .newMessage(sessionId: "session-1", remoteId: .init(value: "foo")),
            body: "Message subject",
            action: .markAsRead
        )

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.setPrimaryAccountInvocations == [])
        #expect(urlOpener.openURLInvocations == [])
    }

    @Test
    func givenURLTypeNotification_whenUserOpensIt_doesNotSwitchThePrimaryAccount() async {
        let response = makeNotificationResponse(type: .urlToOpen(testURL.absoluteString), action: nil)

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.setPrimaryAccountInvocations.isEmpty)
    }

    @Test
    func givenURLTypeNotification_whenUserOpensIt_opensURL() async {
        let response = makeNotificationResponse(type: .urlToOpen(testURL.absoluteString), action: nil)

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(urlOpener.openURLInvocations == [testURL])
    }

    private func makeNotificationResponse(type: RemoteNotificationType, body: String = "", action: NotificationQuickAction?) -> UNNotificationResponse {
        let content = UNMutableNotificationContent()
        content.body = body

        switch type {
        case .newMessage(let sessionId, let remoteId):
            content.userInfo["UID"] = sessionId
            content.userInfo["messageId"] = remoteId.value
        case .urlToOpen(let url):
            content.userInfo["url"] = url
            content.userInfo["UID"] = "foo"
        }

        return UNNotificationResponseStubFactory.makeResponse(
            actionIdentifier: action?.registrableAction().identifier ?? UNNotificationDefaultActionIdentifier,
            content: content
        )
    }
}
