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

import proton_app_uniffi
import Testing

@testable import ProtonMail

final class DeviceTokenRegistrarTests {
    private let sut = DeviceTokenRegistrar()
    private let mailSession = MailSessionSpy()

    private let deviceToken = Data("foo".utf8)

    private var uploadDeviceTokenInvocations: [(String, [StoredSession])] = []

    init() {
        sut.uploadDeviceToken = { [unowned self] in
            self.uploadDeviceTokenInvocations.append(($0, $1))
        }
    }

    @Test
    func onlyAfterDeviceTokenIsReceived_uploadsTokenForAuthenticatedSessions() async throws {
        mailSession.storedSessions = [
            .init(id: "foo", state: .authenticated),
            .init(id: "bar", state: .needKey)
        ]

        try await sut.startWatchingMailSessionForSessions(mailSession)

        try await waitForPublishers()
        #expect(uploadDeviceTokenInvocations.isEmpty)

        sut.onDeviceTokenReceived(deviceToken)

        try await waitForPublishers()
        #expect(idsOfSessionsPerEachRecordedInvocation() == [Set(["foo"])])
    }

    @Test
    func whenSessionIsLoggedOutOrRemoved_doesNotReuploadTokenForRemainingSessions() async throws {
        mailSession.storedSessions = [
            .init(id: "foo", state: .authenticated),
            .init(id: "bar", state: .authenticated)
        ]

        try await sut.startWatchingMailSessionForSessions(mailSession)

        sut.onDeviceTokenReceived(deviceToken)

        try await waitForPublishers()
        #expect(idsOfSessionsPerEachRecordedInvocation() == [Set(["foo", "bar"])])

        mailSession.storedSessions[0] = .init(id: "foo", state: .needKey)

        try await waitForPublishers()
        #expect(uploadDeviceTokenInvocations.count == 1)

        mailSession.storedSessions.remove(at: 0)

        try await waitForPublishers()
        #expect(uploadDeviceTokenInvocations.count == 1)
    }

    @Test
    func whenSessionIsAuthenticatedLater_uploadsTokenForThatSessionOnly() async throws {
        mailSession.storedSessions.append(.init(id: "foo", state: .authenticated))

        try await sut.startWatchingMailSessionForSessions(mailSession)

        sut.onDeviceTokenReceived(deviceToken)

        try await waitForPublishers()
        #expect(idsOfSessionsPerEachRecordedInvocation() == [Set(["foo"])])

        mailSession.storedSessions.append(.init(id: "bar", state: .needKey))

        try await waitForPublishers()
        #expect(idsOfSessionsPerEachRecordedInvocation() == [Set(["foo"])])

        mailSession.storedSessions[1] = .init(id: "bar", state: .authenticated)

        try await waitForPublishers()
        #expect(idsOfSessionsPerEachRecordedInvocation() == [Set(["foo"]), Set(["bar"])])
    }

    private func idsOfSessionsPerEachRecordedInvocation() -> [Set<String>] {
        uploadDeviceTokenInvocations.map { Set($1.map { $0.sessionId() }) }
    }

    private func waitForPublishers() async throws {
        try await Task.sleep(for: .milliseconds(50))
    }
}
