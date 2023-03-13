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

final class BlockedSendersViewModel: NSObject {
    private  let dependencies: Dependencies

    private var cellModels: [BlockedSenderCellModel] {
        switch state {
        case .fetchInProgress:
            return []
        case .blockedSendersFetched(let models):
            return models
        }
    }

    private(set) var state: State = .fetchInProgress {
        didSet {
            guard state != oldValue else {
                return
            }

            uiDelegate?.refreshView(state: state)
        }
    }

    private weak var uiDelegate: BlockedSendersViewModelUIDelegate?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        super.init()

        trackLifetime()
    }

    private func respondToCacheUpdater(state cacheUpdaterState: BlockedSenderCacheUpdater.State) {
        switch cacheUpdaterState {
        case .idle:
            let incomingDefaults: [IncomingDefaultEntity]

            do {
                incomingDefaults = try dependencies.incomingDefaultService.listLocal(location: .blocked)
            } catch {
                assertionFailure("\(error)")
                incomingDefaults = []
            }

            let cellModels = incomingDefaults.map { incomingDefault in
                BlockedSenderCellModel(title: incomingDefault.email)
            }

            state = .blockedSendersFetched(cellModels)
        default:
            state = .fetchInProgress
        }
    }
}

extension BlockedSendersViewModel: BlockedSendersViewModelInput {
    func viewWillAppear() {
        dependencies.cacheUpdater.delegate = self
        respondToCacheUpdater(state: dependencies.cacheUpdater.state)
    }

    func userDidPullToRefresh() {
        dependencies.cacheUpdater.requestUpdate(force: true)
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

    struct Dependencies {
        let cacheUpdater: BlockedSenderCacheUpdater
        let incomingDefaultService: IncomingDefaultService
    }

    enum State: Equatable {
        case blockedSendersFetched([BlockedSenderCellModel])
        case fetchInProgress
    }
}
