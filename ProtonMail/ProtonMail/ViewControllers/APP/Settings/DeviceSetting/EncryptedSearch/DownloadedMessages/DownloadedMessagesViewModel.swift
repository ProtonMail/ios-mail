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

import Foundation

final class DownloadedMessagesViewModel: DownloadedMessagesViewModelProtocol {
    var input: DownloadedMessagesViewModelInput { self }
    var output: DownloadedMessagesViewModelOutput { self }
    private let router: DownloadedMessagesRouterProtocol
    let searchIndexState: EncryptedSearchIndexState
    let dateFormatter: DateFormatter
    private weak var uiDelegate: DownloadedMessagesUIProtocol?
    private var dependencies: Dependencies

    private var userID: UserID {
        dependencies.userID
    }

    init(
        router: DownloadedMessagesRouterProtocol,
        searchIndexState: EncryptedSearchIndexState,
        dependencies: Dependencies
    ) {
        self.dateFormatter = DateFormatter.EncryptedSearch.formatterForOldestMessage()
        self.router = router
        self.searchIndexState = searchIndexState
        self.dependencies = dependencies
    }
}

extension DownloadedMessagesViewModel: DownloadedMessagesViewModelInput {

    func didChangeStorageLimitValue(newValue: ByteCount) {
        guard newValue > 0 else {
            uiDelegate?.reloadData()
            return
        }
        dependencies.esDeviceCache.storageLimit = newValue
    }

    func didTapClearStorageUsed() {
        dependencies.esUserCache.setIsEncryptedSearchOn(of: userID, value: false)
        dependencies.esService.stopBuildingIndex(for: userID)
        router.closeView()
    }
}

extension DownloadedMessagesViewModel: DownloadedMessagesViewModelOutput {
    var sections: [DownloadedMessagesSection] {
        [.messageHistory, .storageLimit, .localStorageUsed]
    }

    var storageLimitSelected: ByteCount {
        dependencies.esDeviceCache.storageLimit
    }

    var localStorageUsed: ByteCount {
        dependencies.esService.indexSize(for: userID) ?? 0
    }

    var oldestMessageTime: String {
        var oldestTime: String = "-"
        if let time = dependencies.esService.oldesMessageTime(for: userID) {
            oldestTime = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
        }
        return oldestTime
    }

    func setUIDelegate(_ delegate: DownloadedMessagesUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension DownloadedMessagesViewModel {

    struct Dependencies {
        let userID: UserID
        var esDeviceCache: EncryptedSearchDeviceCache
        let esUserCache: EncryptedSearchUserCache
        let esService: EncryptedSearchServiceProtocol

        init(
            userID: UserID,
            esDeviceCache: EncryptedSearchDeviceCache = sharedServices.get(by: EncryptedSearchUserDefaultCache.self),
            esUserCache: EncryptedSearchUserCache = sharedServices.get(by: EncryptedSearchUserDefaultCache.self),
            esService: EncryptedSearchServiceProtocol = EncryptedSearchService.shared
        ) {
            self.userID = userID
            self.esDeviceCache = esDeviceCache
            self.esUserCache = esUserCache
            self.esService = esService
        }
    }
}
