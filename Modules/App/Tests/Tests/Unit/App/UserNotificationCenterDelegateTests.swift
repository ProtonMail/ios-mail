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
import InboxCore
import proton_app_uniffi
import Testing
import UIKit

@testable import ProtonMail

final class UserNotificationCenterDelegateTests {
    private let mailSession: MailSessionSpy
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(.noSession)
    private let urlOpener = URLOpenerSpy()
    private let userNotificationCenter = UserNotificationCenterSpy()
    private let sut: UserNotificationCenterDelegate

    private let testURL = URL(string: "https://example.com")!

    init() {
        let mailSession = MailSessionSpy()

        mailSession.storedSessions = [
            .init(id: "session-1", userId: "user-1", state: .authenticated),
            .init(id: "session-2", userId: "user-2", state: .authenticated)
        ]

        self.mailSession = mailSession

        sut = .init(
            sessionStatePublisher: sessionStateSubject.eraseToAnyPublisher(),
            urlOpener: urlOpener,
            userNotificationCenter: userNotificationCenter
        ) { mailSession }

        mailSession.onPrimaryAccountChanged = { [unowned self] userId in
            let sessionAssociatedWithUserId = mailSession.storedSessions.first { $0.userId() == userId }!

            sessionStateSubject.send(
                .activeSession(session: MailUserSessionStub(id: sessionAssociatedWithUserId.sessionId()))
            )
        }
    }

    deinit {
        mailSession.onPrimaryAccountChanged = nil
    }

    @Test
    func whenServicesAreSetUp_assignsItselfAsUserNotificationCenterDelegate() {
        sut.setUpService()

        #expect(userNotificationCenter.delegate === sut)
    }

    @Test
    func whenNotificationIsReceivedInForeground_presentsItWithBannerAndSound() async {
        let notification = UNNotificationResponseStubFactory.makeNotification(content: .init())

        let options = await sut.userNotificationCenter(.current(), willPresent: notification)

        #expect(options == [.banner, .list, .sound])
    }

    @Test
    func givenMessageTypeNotification_whenUserOpensIt_switchesThePrimaryAccount() async throws {
        let response = makeNotificationResponse(type: .newMessage(sessionId: "session-2", remoteId: ""))

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.setPrimaryAccountInvocations == ["user-2"])
    }

    @Test
    func givenMessageTypeNotification_whenUserOpensIt_navigatesToMessageThroughDeepLink() async {
        let response = makeNotificationResponse(
            type: .newMessage(sessionId: "session-1", remoteId: "foo"),
            body: "Message subject"
        )

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(urlOpener.openURLInvocations == [URL(string: "protonmailET://messages/foo?subject=Message%20subject")!])
    }

    @Test
    func givenURLTypeNotification_whenUserOpensIt_doesNotSwitchThePrimaryAccount() async {
        let response = makeNotificationResponse(type: .urlToOpen(testURL.absoluteString))

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(mailSession.setPrimaryAccountInvocations.isEmpty)
    }

    @Test
    func givenURLTypeNotification_whenUserOpensIt_opensURL() async {
        let response = makeNotificationResponse(type: .urlToOpen(testURL.absoluteString))

        await sut.userNotificationCenter(.current(), didReceive: response)

        #expect(urlOpener.openURLInvocations == [testURL])
    }

    private func makeNotificationResponse(type: RemoteNotificationType, body: String = "") -> UNNotificationResponse {
        let content = UNMutableNotificationContent()
        content.body = body

        switch type {
        case .newMessage(let sessionId, let remoteId):
            content.userInfo["UID"] = sessionId
            content.userInfo["messageId"] = remoteId
        case .urlToOpen(let url):
            content.userInfo["url"] = url
            content.userInfo["UID"] = "foo"
        }

        return UNNotificationResponseStubFactory.makeResponse(content: content)
    }
}

private class URLOpenerSpy: URLOpener {
    private(set) var openURLInvocations: [URL] = []

    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any]) async -> Bool {
        openURLInvocations.append(url)
        return true
    }
}

private final class MailUserSessionStub: MailUserSession {
    private let id: String

    init(id: String) {
        self.id = id

        super.init(noPointer: .init())
    }

    @available(*, unavailable)
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    override func sessionId() -> MailUserSessionSessionIdResult {
        .ok(id)
    }
}
