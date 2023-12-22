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

import Combine
import LifetimeTracker

final class BlockedSendersViewModel {
    typealias Dependencies = HasBlockedSenderCacheUpdater
    & HasCoreDataContextProviderProtocol
    & HasUnblockSender
    & HasUserManager

    private let dependencies: Dependencies
    private let blockedSendersPublisher: BlockedSendersPublisher
    private var cancellables = Set<AnyCancellable>()

    private var cellModels: [BlockedSenderCellModel] = [] {
        didSet {
            notifyView()
        }
    }

    private var isRefreshInProgress = false {
        didSet {
            notifyView()
        }
    }

    private weak var uiDelegate: BlockedSendersViewModelUIDelegate?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        blockedSendersPublisher = BlockedSendersPublisher(
            contextProvider: dependencies.contextProvider,
            userID: dependencies.user.userID
        )

        trackLifetime()
    }

    private func setupBinding() {
        blockedSendersPublisher.contentDidChange
            .map { $0.map { BlockedSenderCellModel(title: $0.email) } }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cellModels in
                self?.cellModels = cellModels
            }
            .store(in: &cancellables)

        blockedSendersPublisher.start()
    }

    private func notifyView() {
        uiDelegate?.refreshView(state: isRefreshInProgress ? .fetchInProgress : .blockedSendersFetched(cellModels))
    }

    private func respondToCacheUpdater(state cacheUpdaterState: BlockedSenderCacheUpdater.State) {
        isRefreshInProgress = cacheUpdaterState != .idle

        if cacheUpdaterState == .waitingToBecomeOnline {
            uiDelegate?.showOfflineToast()
        }
    }
}

extension BlockedSendersViewModel: BlockedSendersViewModelInput {
    func deleteRow(at indexPath: IndexPath) throws {
        guard let cellModel = cellModels[safe: indexPath.row] else {
            return
        }

        let senderEmail = cellModel.title
        let parameters = UnblockSender.Parameters(emailAddress: senderEmail)
        try dependencies.unblockSender.execute(parameters: parameters)
    }

    func viewDidLoad() {
        setupBinding()
    }

    func viewWillAppear() {
        dependencies.blockedSenderCacheUpdater.delegate = self
        respondToCacheUpdater(state: dependencies.blockedSenderCacheUpdater.state)
    }

    func userDidPullToRefresh() {
        dependencies.blockedSenderCacheUpdater.requestUpdate(force: true)
    }
}

extension BlockedSendersViewModel: BlockedSenderCacheUpdaterDelegate {
    func blockedSenderCacheUpdater(
        _ blockedSenderCacheUpdater: BlockedSenderCacheUpdater,
        didEnter newState: BlockedSenderCacheUpdater.State
    ) {
        DispatchQueue.main.async {
            self.respondToCacheUpdater(state: newState)
        }
    }
}

extension BlockedSendersViewModel: BlockedSendersViewModelOutput {
    func numberOfRows() -> Int {
        cellModels.count
    }

    func setUIDelegate(_ delegate: BlockedSendersViewModelUIDelegate) {
        uiDelegate = delegate
    }

    func modelForCell(at indexPath: IndexPath) -> BlockedSendersViewModel.BlockedSenderCellModel {
        cellModels[indexPath.row]
    }
}

extension BlockedSendersViewModel: BlockedSendersViewModelProtocol {
    var input: BlockedSendersViewModelInput { self }
    var output: BlockedSendersViewModelOutput { self }
}

extension BlockedSendersViewModel: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension BlockedSendersViewModel {
    struct BlockedSenderCellModel: Equatable {
        let title: String
    }

    enum State: Equatable {
        case blockedSendersFetched([BlockedSenderCellModel])
        case fetchInProgress
    }
}
