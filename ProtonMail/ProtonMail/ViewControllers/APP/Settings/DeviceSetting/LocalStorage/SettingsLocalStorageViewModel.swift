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

final class SettingsLocalStorageViewModel: SettingsLocalStorageViewModelProtocol {
    var input: SettingsLocalStorageViewModelInput { self }
    var output: SettingsLocalStorageViewModelOutput { self }
    private weak var uiDelegate: SettingsLocalStorageUIProtocol?
    private let router: SettingsLocalStorageRouterProtocol
    private let dependencies: Dependencies

    init(router: SettingsLocalStorageRouterProtocol, dependencies: Dependencies) {
        self.router = router
        self.dependencies = dependencies
    }
}

extension SettingsLocalStorageViewModel: SettingsLocalStorageViewModelInput {

    func didTapClearData() {
        // TODO: use the dependency
//        dependencies.localStorageProvider.clearCacheData()
    }

    func didTapClearAttachments() {
        // TODO: use the dependency
//        dependencies.localStorageProvider.clearAttachments()
    }

    func didTapDownloadedMessages() {
        router.navigateToDownloadedMessages()
    }
}

extension SettingsLocalStorageViewModel: SettingsLocalStorageViewModelOutput {
    var sections: [SettingsLocalStorageSection] {
        [.cachedData, .attachments, .downloadedMessages]
    }

    var cachedDataStorage: ByteCount {
        // TODO: use the dependency
//        return dependencies.localStorageProvider.cacheDataStorageUsed
        return 100_000_000
    }

    var attachmentsStorage: ByteCount {
        // TODO: use the dependency
//        return dependencies.localStorageProvider.attachmentsStorageUsed
        return 338_000_000
    }

    var downloadedMessagesStorage: ByteCount {
        // TODO: use the dependency
//        return dependencies.localStorageProvider.encryptedSearchStorageUsedActiveAccount
        return 72_000_000
    }

    func setUIDelegate(_ delegate: SettingsLocalStorageUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension SettingsLocalStorageViewModel {

    struct Dependencies {
        // TODO: use the dependency
//        let localStorageProvider: LocalStorageProvider
    }
}
