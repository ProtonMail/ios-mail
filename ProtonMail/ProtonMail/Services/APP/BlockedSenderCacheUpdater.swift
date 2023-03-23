// Copyright (c) 2023 Proton Technologies AG
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

import LifetimeTracker
import ProtonCore_DataModel

// sourcery: mock
protocol BlockedSenderCacheUpdaterDelegate: AnyObject {
    func blockedSenderCacheUpdater(
        _ blockedSenderCacheUpdater: BlockedSenderCacheUpdater,
        didEnter newState: BlockedSenderCacheUpdater.State
    )
}

final class BlockedSenderCacheUpdater {
    private let dependencies: Dependencies
    private let observerID = UUID()

    // Side effects cannot be happening synchronously in didSet, because they might write to the `state` property themselves.
    // That would result in nested execution and issues like the delegate receiving events in reverse order.
    private let sideEffectQueue = DispatchQueue(label: "me.proton.mail.blockedSendersUpdate")

    weak var delegate: BlockedSenderCacheUpdaterDelegate?

    private(set) var state: State = .idle {
        didSet {
            SystemLogger.log(message: "CacheUpdater state: \(oldValue) -> \(state)", category: .blockSender)

            guard oldValue != state else {
                let errorMessage = "Setting \(oldValue) twice"
                SystemLogger.log(message: errorMessage, category: .blockSender, isError: true)
                assertionFailure(errorMessage)
                return
            }

            // capture state as a local constant before it is mutated
            sideEffectQueue.async { [state, weak self] in
                guard let self = self else {
                    return
                }

                // side-effects of leaving old state
                switch oldValue {
                case .waitingToBecomeOnline:
                    self.unregisterFromConnectivityUpdates()
                default:
                    break
                }

                // side-effects of entering new state
                switch state {
                case .idle:
                    self.markUpdateAsFinished()
                case .updateRequested:
                    self.attemptUpdateIfOnline()
                case .updateInProgress:
                    self.beginUpdate()
                case .waitingToBecomeOnline:
                    self.registerForConnectivityUpdates()
                case .waitingToRetryAfterError:
                    self.scheduleRetry()
                }

                self.delegate?.blockedSenderCacheUpdater(self, didEnter: state)
            }
        }
    }

    private var userID: UserID {
        .init(dependencies.userInfo.userId)
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        trackLifetime()
    }

    /// parameter force: ignore the local flag that the fetch has been completed previously
    func requestUpdate(force: Bool = false) {
        guard state == .idle else {
            return
        }

        guard force || !dependencies.fetchStatusProvider.checkIfBlockedSendersAreFetched(userID: userID) else {
            return
        }

        state = .updateRequested
    }

    private func markUpdateAsFinished() {
        dependencies.fetchStatusProvider.markBlockedSendersAsFetched(userID: userID)
    }

    private func attemptUpdateIfOnline() {
        if dependencies.internetConnectionStatusProvider.currentStatus.isConnected {
            state = .updateInProgress
        } else {
            state = .waitingToBecomeOnline
        }
    }

    private func registerForConnectivityUpdates() {
        dependencies.internetConnectionStatusProvider.registerConnectionStatus(
            observerID: observerID
        ) { [weak self] status in
            if status.isConnected {
                self?.state = .updateInProgress
            }
        }
    }

    private func unregisterFromConnectivityUpdates() {
        dependencies.internetConnectionStatusProvider.unregisterObserver(observerID: observerID)
    }

    private func beginUpdate() {
        dependencies.refetchAllBlockedSenders.execute { [weak self] error in
            if let error = error {
                SystemLogger.log(message: "Failed to fetch blocked senders: \(error)", category: .blockSender, isError: true)
                self?.state = .waitingToRetryAfterError
            } else {
                self?.state = .idle
            }
        }
    }

    private func scheduleRetry() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.state = .updateRequested
        }
    }
}

extension BlockedSenderCacheUpdater: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension BlockedSenderCacheUpdater {
    struct Dependencies {
        let fetchStatusProvider: BlockedSenderFetchStatusProviderProtocol
        let internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol
        let refetchAllBlockedSenders: RefetchAllBlockedSendersUseCase
        let userInfo: UserInfo
    }

    enum State {
        case idle
        case updateRequested
        case updateInProgress
        case waitingToBecomeOnline
        case waitingToRetryAfterError
    }
}
