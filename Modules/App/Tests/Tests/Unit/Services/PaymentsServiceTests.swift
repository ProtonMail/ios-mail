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

@testable import PaymentsNG
@testable import ProtonMail

@MainActor
final class PaymentsServiceTests {
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(.noSession)
    private let transactionStatusSubject = CurrentValueSubject<TransactionType, Never>(.unknown)
    private let transactionsObserver = TransactionsObserverSpy()
    private var refreshUserDataCalls = 0

    private lazy var sut = PaymentsService(
        sessionState: sessionStateSubject,
        transactionStatus: transactionStatusSubject,
        transactionsObserver: transactionsObserver,
        refreshUserData: { [unowned self] in refreshUserDataCalls += 1 }
    )

    @Test
    func handlesEverySessionTransitionWithoutSkippingElements() async {
        let userSession1 = MailUserSessionSpy(id: "foo")
        let userSession2 = MailUserSessionSpy(id: "bar")

        let task = sut.startListeningToUserSessionChanges()

        let incomingSessionStates: [SessionState] = [
            .restoring,
            .activeSession(session: userSession1),
            .initializing,
            .activeSession(session: userSession2),
            .activeSession(session: userSession1),
            .noSession,
        ]

        for incomingSessionState in incomingSessionStates {
            sessionStateSubject.send(incomingSessionState)
        }

        await waitForEventHandlingToFinish(task: task)

        let expectedCalls: [TransactionsObserverSpy.Call] = [
            .setConfiguration(sessionId: "foo"),
            .start,
            .stop,
            .setConfiguration(sessionId: "bar"),
            .start,
            .stop,
            .setConfiguration(sessionId: "foo"),
            .start,
            .stop,
        ]

        #expect(transactionsObserver.recordedCalls == expectedCalls)
    }

    @Test
    func pollsEventLoopAfterSuccessfulTransaction() async {
        let task = sut.startListeningToSuccessfulPurchases()

        transactionStatusSubject.send(.successful)

        await waitForEventHandlingToFinish(task: task)

        #expect(refreshUserDataCalls == 1)
    }

    @Test
    func doesNotPollEventLoopAfterOtherTransactionEvents() async {
        let task = sut.startListeningToSuccessfulPurchases()

        transactionStatusSubject.send(.failed)
        transactionStatusSubject.send(.renewal)
        transactionStatusSubject.send(.alreadyProcessed)
        transactionStatusSubject.send(.unknown)

        await waitForEventHandlingToFinish(task: task)

        #expect(refreshUserDataCalls == 0)
    }

    private func waitForEventHandlingToFinish(task: Task<Void, Never>) async {
        sessionStateSubject.send(completion: .finished)
        transactionStatusSubject.send(completion: .finished)
        await task.value
    }
}

private final class TransactionsObserverSpy: TransactionsObserverProviding {
    enum Call: Equatable {
        case stop
        case start
        case setConfiguration(sessionId: String)
    }

    private(set) var recordedCalls: [Call] = []

    func start() async {
        await simulateNetworkDelay()
        recordedCalls.append(.start)
    }

    private func simulateNetworkDelay() async {
        try! await Task.sleep(for: .milliseconds(10))
    }

    func stop() {
        recordedCalls.append(.stop)
    }

    func setConfiguration(_ configuration: TransactionsObserverConfiguration) {
        let sessionId = try! configuration.rustSession.sessionId().get()
        recordedCalls.append(.setConfiguration(sessionId: sessionId))
    }

    func addTransactionInProgress(_ transactionId: UInt64) {
        fatalError(#function)
    }

    func removeTransactionInProgress(_ transactionId: UInt64) {
        fatalError(#function)
    }

    func generateTransactionLog() -> URL? {
        fatalError(#function)
    }

    func deleteLogs() async {
        fatalError(#function)
    }
}
