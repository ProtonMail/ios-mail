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

final class SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelProtocol {
    var input: SettingsEncryptedSearchViewModelInput { self }
    var output: SettingsEncryptedSearchViewModelOutput { self }
    private weak var uiDelegate: SettingsEncryptedSearchUIProtocol?
    private let router: SettingsEncryptedSearchRouterProtocol
    private let dependencies: Dependencies

    private var userID: UserID {
        dependencies.userID
    }
    private(set) var sections: [SettingsEncryptedSearchSection] = [.encryptedSearchFeature]

    init(router: SettingsEncryptedSearchRouterProtocol, dependencies: Dependencies) {
        self.router = router
        self.dependencies = dependencies
    }

    private func refreshEnabledStatusUI() {
        if isEncryptedSearchEnabled {
            sections = [.encryptedSearchFeature, .downloadViaMobileData]
            if isDownloadInProgress {
                sections.append(.downloadProgress)
            } else {
                sections.append(.downloadedMessages)
            }
        } else {
            sections = [.encryptedSearchFeature]
        }
        uiDelegate?.reloadData()
    }
}

extension SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelInput {

    func viewWillAppear() {
        dependencies.esService.setBuildSearchIndexDelegate(for: userID, delegate: self)
        let state = dependencies.esService.indexBuildingState(for: userID)
        uiDelegate?.updateDownloadState(state: state)
    }

    func didChangeEncryptedSearchValue(isNewStatusEnabled: Bool) {
        dependencies.esUserCache.setIsEncryptedSearchOn(of: userID, value: isNewStatusEnabled)
        if isNewStatusEnabled {
            dependencies.esService.startBuildingIndex(for: userID)
        } else {
            dependencies.esService.stopBuildingIndex(for: userID)
        }
        refreshEnabledStatusUI()
    }

    func didChangeUseMobileDataValue(isNewStatusEnabled: Bool) {
        dependencies.esUserCache.setCanDownloadViaMobileData(of: userID, value: isNewStatusEnabled)
        dependencies.esService.didChangeDownloadViaMobileData(for: userID)
    }

    func didTapDownloadedMessages() {
        router.navigateToDownloadedMessages()
    }

    func didTapPauseMessagesDownload() {
        dependencies.esService.pauseBuildingIndex(for: userID)
    }

    func didTapResumeMessagesDownload() {
        dependencies.esService.resumeBuildingIndex(for: userID)
    }
}

extension SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelOutput {
    var searchIndexState: EncryptedSearchIndexState {
        dependencies.esService.indexBuildingState(for: userID)
    }

    var isEncryptedSearchEnabled: Bool {
        dependencies.esUserCache.isEncryptedSearchOn(of: userID)
    }

    var isUseMobileDataEnabled: Bool {
        dependencies.esUserCache.canDownloadViaMobileData(of: userID)
    }

    var isDownloadInProgress: Bool {
        dependencies.esService.isIndexBuildingInProgress(for: userID)
    }

    var searchIndexDownloadProgress: EncryptedSearchDownloadProgress? {
        dependencies.esService.indexBuildingEstimatedProgress(for: userID)?.toEncryptedSearchDownloadProgress()
    }

    func setUIDelegate(_ delegate: SettingsEncryptedSearchUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension SettingsEncryptedSearchViewModel: BuildSearchIndexDelegate {

    func indexBuildingStateDidChange(state: EncryptedSearchIndexState) {
        refreshEnabledStatusUI()
        uiDelegate?.updateDownloadState(state: state)
    }

    func indexBuildingProgressUpdate(progress: BuildSearchIndexEstimatedProgress) {
        uiDelegate?.updateDownloadProgress(progress: progress.toEncryptedSearchDownloadProgress())
    }
}

private extension BuildSearchIndexEstimatedProgress {

    func toEncryptedSearchDownloadProgress() -> EncryptedSearchDownloadProgress {
        .init(
            numMessagesDownloaded: indexedMessages,
            totalMessages: totalMessages,
            timeRemaining: estimatedTimeString ?? "",
            percentageDownloaded: Int(floor(currentProgress))
        )
    }
}

extension SettingsEncryptedSearchViewModel {

    struct Dependencies {
        let userID: UserID
        let esUserCache: EncryptedSearchUserCache
        let esService: EncryptedSearchServiceProtocol
        let internetStatus: InternetConnectionStatusProvider

        init(
            userID: UserID,
            esUserCache: EncryptedSearchUserCache = sharedServices.get(by: EncryptedSearchUserDefaultCache.self),
            esService: EncryptedSearchServiceProtocol = EncryptedSearchService.shared,
            internetStatus: InternetConnectionStatusProvider = InternetConnectionStatusProvider()
        ) {
            self.userID = userID
            self.esUserCache = esUserCache
            self.esService = esService
            self.internetStatus = internetStatus
        }
    }
}
