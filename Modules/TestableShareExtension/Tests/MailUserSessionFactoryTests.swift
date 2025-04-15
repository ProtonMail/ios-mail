//
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

import Testing
import proton_app_uniffi

@testable import TestableShareExtension

final class MailUserSessionFactoryTests {
    private lazy var sut: MailUserSessionFactory = {
        .init { [unowned self] _, _ in
            self.createMailSessionCallCount += 1
            return .ok(FakeMailSession(noPointer: .init()))
        }
    }()

    private var createMailSessionCallCount = 0

    @Test
    func testSubsequentMakeInvocationsReuseCachedSession() async throws {
        for _ in 0...3 {
            _ = try await sut.make()
        }

        #expect(createMailSessionCallCount == 1)
    }
}

private final class FakeMailSession: MailSession, @unchecked Sendable {
    override func getPrimaryAccount() async -> MailSessionGetPrimaryAccountResult {
        .ok(.init(noPointer: .init()))
    }

    override func getAccountSessions(account: StoredAccount) async -> MailSessionGetAccountSessionsResult {
        .ok([.init(noPointer: .init())])
    }

    override func userContextFromSession(session: StoredSession) async -> MailSessionUserContextFromSessionResult {
        .ok(.init(noPointer: .init()))
    }
}
