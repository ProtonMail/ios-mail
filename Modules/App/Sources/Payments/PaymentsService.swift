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

@preconcurrency import Combine
import InboxCore
import PaymentsNG
import proton_app_uniffi

@MainActor
final class PaymentsService: ApplicationServiceSetUp {
    private let sessionState: AnyPublisher<SessionState, Never>
    private let transactionStatus: AnyPublisher<TransactionType, Never>
    private let transactionsObserver: TransactionsObserverProviding
    private let refreshUserData: () async -> Void

    init(
        sessionState: any Publisher<SessionState, Never>,
        transactionStatus: any Publisher<TransactionType, Never>,
        transactionsObserver: TransactionsObserverProviding,
        refreshUserData: @escaping () async -> Void
    ) {
        self.sessionState = sessionState.eraseToAnyPublisher()
        self.transactionStatus = transactionStatus.eraseToAnyPublisher()
        self.transactionsObserver = transactionsObserver
        self.refreshUserData = refreshUserData
    }

    convenience init(appContext: AppContext) {
        let transactionsObserver = TransactionsObserver.shared

        self.init(
            sessionState: appContext.$sessionState,
            transactionStatus: transactionsObserver.$transactionStatus,
            transactionsObserver: transactionsObserver,
            refreshUserData: appContext.pollEventsAsync
        )
    }

    func setUpService() {
        startListeningToUserSessionChanges()
        startListeningToSuccessfulPurchases()
    }

    @discardableResult
    func startListeningToUserSessionChanges() -> Task<Void, Never> {
        let userSessionChanges = sessionState.removeDuplicates().map(\.userSession).withPrevious().valuesWithBuffering

        return .init { [transactionsObserver] in
            for await (previousSession, currentSession) in userSessionChanges {
                if let previousSession {
                    AppLogger.log(message: "Stopping observation for \(previousSession.sessionIdentifier)", category: .payments)
                    transactionsObserver.stop()
                }

                if let currentSession {
                    transactionsObserver.setConfiguration(.init(rustSession: currentSession))

                    do {
                        AppLogger.log(message: "Starting observation for \(currentSession.sessionIdentifier)", category: .payments)
                        try await transactionsObserver.start()
                        AppLogger.log(message: "Observation started for \(currentSession.sessionIdentifier)", category: .payments)
                    } catch {
                        AppLogger.log(error: error, category: .payments)
                    }
                }
            }
        }
    }

    @discardableResult
    func startListeningToSuccessfulPurchases() -> Task<Void, Never> {
        let refreshTriggers = transactionStatus.filter { $0 == .successful }.map { _ in }.valuesWithBuffering

        return .init {
            for await _ in refreshTriggers {
                await refreshUserData()
            }
        }
    }
}

private extension Publisher {
    func withPrevious<T>() -> AnyPublisher<(previous: Output, current: Output), Failure> where Output == T? {
        scan((nil, nil)) { ($0.1, $1) }.eraseToAnyPublisher()
    }
}

private extension MailUserSession {
    var sessionIdentifier: String {
        switch sessionId() {
        case .ok(let id):
            return id
        case .error(let error):
            AppLogger.log(error: error, category: .userSessions)
            return "unknown session"
        }
    }
}
