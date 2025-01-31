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

@testable import ProtonMail
import XCTest
import proton_app_uniffi

import InboxTesting

class EmailsPrefetchingTriggerTests: BaseTestCase {

    var sut: EmailsPrefetchingTrigger!
    var emailsPrefetchingNotifier: EmailsPrefetchingNotifier!
    var prefetchCallCount: Int!
    private var sessionProviderStub: SessionProviderStubb!

    override func setUp() {
        super.setUp()

        prefetchCallCount = 0
        emailsPrefetchingNotifier = .init()
        sessionProviderStub = SessionProviderStubb()
        sut = EmailsPrefetchingTrigger(
            emailsPrefetchingNotifier: emailsPrefetchingNotifier,
            sessionProvider: sessionProviderStub,
            prefetch: { _ in
                self.prefetchCallCount += 1
                return .ok
            }
        )
    }

    override func tearDown() {
        sut = nil
        emailsPrefetchingNotifier = nil
        sessionProviderStub = nil
        prefetchCallCount = nil

        super.tearDown()
    }

    func test_WhenUserIsNotAuthorized_WhenPrefetchingIsNotified_ItShouldNotTriggerPrefetching() {
        sessionProviderStub.stubbedSessionState = .noSession
        sut.setUpSubscription()

        emailsPrefetchingNotifier.notify()

        XCTAssertEqual(prefetchCallCount, 0)
    }

    func test_WhenUserIsAuthorized_WhenPrefetchingIsNotified_ItShouldTriggerPrefetching() {
        sessionProviderStub.stubbedSessionState = .activeSession(session: .dummy)
        sut.setUpSubscription()

        emailsPrefetchingNotifier.notify()

        XCTAssertEqual(prefetchCallCount, 1)
    }

}

private class SessionProviderStubb: SessionProvider {

    var stubbedSessionState: SessionState = .noSession

    // MARK: - SessionProvider

    var sessionState: SessionState {
        stubbedSessionState
    }

    var userSession: MailUserSession {
        .dummy
    }

}
