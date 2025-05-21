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

final class PaymentsService: ApplicationServiceSetUp {
    private let sessionState: AnyPublisher<SessionState, Never>
    private let transactionsObserver: TransactionsObserverProviding

    init(
        sessionState: any Publisher<SessionState, Never>,
        transactionsObserver: TransactionsObserverProviding = TransactionsObserver.shared
    ) {
        self.sessionState = sessionState.eraseToAnyPublisher()
        self.transactionsObserver = transactionsObserver
    }

    func setUpService() {
        _ = startListeningToUserSessionChanges()
    }

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
}

private extension Publisher {
    func withPrevious<T>() -> AnyPublisher<(previous: Output, current: Output), Failure> where Output == T? {
        scan((nil, nil)) { ($0.1, $1) }.eraseToAnyPublisher()
    }
}

private extension Publisher where Output: Sendable, Failure == Never {
    /// `Publisher.values` does not buffer elements, so if you `await` inside a `for` loop, for example, some elements might be dropped.
    /// This variant uses `AsyncStream` internally, which buffers by default.
    var valuesWithBuffering: AsyncStream<Output> {
        .init { continuation in
            let cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )

            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
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
