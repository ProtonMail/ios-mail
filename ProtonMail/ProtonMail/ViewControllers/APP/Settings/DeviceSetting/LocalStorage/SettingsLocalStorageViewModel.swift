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

    private var userID: UserID {
        dependencies.userID
    }

    init(router: SettingsLocalStorageRouterProtocol, dependencies: Dependencies) {
        self.router = router
        self.dependencies = dependencies

        /* TODO:
         This is a workaround to indirectly create the build index to have index data
         available. The delegate is not needed
        **/
        dependencies.esService.setBuildSearchIndexDelegate(for: userID, delegate: nil)
    }
}

extension SettingsLocalStorageViewModel: SettingsLocalStorageViewModelInput {

    func viewWillAppear() {
        uiDelegate?.reloadData()
    }

    func didTapClearCachedData() {
        uiDelegate?.clearingCacheDidStart()
        dependencies
            .cleanCache
            .execute(params: Void()) { [weak self] result in
                self?.uiDelegate?.clearingCacheDidEnd(error: result.error)
            }
    }

    func didTapClearAttachments() {
        var resultingError: Error?
        uiDelegate?.clearingCacheDidStart()
        let attachmentDirectory = dependencies.fileManager.attachmentDirectory
        do {
            try dependencies.fileManager.removeItem(at: attachmentDirectory)
        } catch {
            resultingError = error
        }
        uiDelegate?.clearingCacheDidEnd(error: resultingError)
    }

    func didTapDownloadedMessages() {
        let state = searchIndexState
        guard state.allowsToShowDownloadedMessagesInfo else { return }
        router.navigateToDownloadedMessages(userID: dependencies.userID, state: state)
    }
}

extension SettingsLocalStorageViewModel: SettingsLocalStorageViewModelOutput {
    var sections: [SettingsLocalStorageSection] {
        [.cachedData, .attachments, .downloadedMessages]
    }

    var searchIndexState: EncryptedSearchIndexState {
        dependencies.esService.indexBuildingState(for: userID)
    }

    var cachedDataStorage: ByteCount {
        /*
         We only read the sqlite file size (and not the WAL or SMH files) because
         sequential clear actions could return bigger sizes. This is because
         the WAL file could grow a little depending on whether it reached it's
         size limit when the data is cleared.

         More info: https://www.sqlite.org/wal.html
         **/
        return ByteCount(dependencies.coreDataMetadata.sqliteFileSize ?? 0)
    }

    var attachmentsStorage: ByteCount {
        dependencies.fileManager.sizeOfDirectory(url: dependencies.fileManager.attachmentDirectory)
    }

    var downloadedMessagesStorage: ByteCount {
        dependencies.esService.indexSize(for: userID) ?? 0
    }

    func setUIDelegate(_ delegate: SettingsLocalStorageUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension SettingsLocalStorageViewModel {

    struct Dependencies {
        let userID: UserID
        let cleanCache: CleanCacheUseCase
        let coreDataMetadata: CoreDataMetadata
        let esService: EncryptedSearchServiceProtocol
        let fileManager: FileManager

        init(
            userID: UserID,
            cleanCache: CleanCacheUseCase = CleanCache(dependencies: .init()),
            coreDataMetada: CoreDataMetadata = CoreDataStore.shared,
            esService: EncryptedSearchServiceProtocol = EncryptedSearchService.shared,
            fileManager: FileManager = .default
        ) {
            self.userID = userID
            self.cleanCache = cleanCache
            self.coreDataMetadata = coreDataMetada
            self.esService = esService
            self.fileManager = fileManager
        }
    }
}
