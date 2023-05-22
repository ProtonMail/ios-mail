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
    let dateFormatter: DateFormatter
    private weak var uiDelegate: SettingsEncryptedSearchUIProtocol?
    private let router: SettingsEncryptedSearchRouterProtocol
    private let dependencies: Dependencies

    private var userID: UserID {
        dependencies.userID
    }
    private(set) var sections: [SettingsEncryptedSearchSection] = [.encryptedSearchFeature]

    init(router: SettingsEncryptedSearchRouterProtocol, dependencies: Dependencies) {
        dateFormatter = DateFormatter
            .EncryptedSearch
            .formatterForOldestMessage(locale: dependencies.locale, timeZone: dependencies.timeZone)
        self.router = router
        self.dependencies = dependencies
    }

    private func refreshEnabledStatusUI() {
        if isEncryptedSearchEnabled {
            sections = [.encryptedSearchFeature, .downloadViaMobileData]
            let indexBuildingState = dependencies.esService.indexBuildingState(for: userID)
            if indexBuildingState != .undetermined { // TODO: we should get rid of the .undeterminate state
                if shouldShowDownloadingProgress(for: indexBuildingState) {
                    sections.append(.downloadProgress)
                } else {
                    sections.append(.downloadedMessages)
                }
            }
        } else {
            sections = [.encryptedSearchFeature]
        }
        uiDelegate?.reloadData()
    }

    private func shouldShowDownloadingProgress(for state: EncryptedSearchIndexState) -> Bool {
        switch state {
        case .disabled, .partial, .complete:
            return false
        case .creatingIndex, .paused, .downloadingNewMessage, .undetermined, .background, .backgroundStopped:
            return true
        }
    }
}

extension SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelInput {

    func viewWillAppear() {
        dependencies.esService.setBuildSearchIndexDelegate(for: userID, delegate: self)
        refreshEnabledStatusUI()
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
        let state = dependencies.esService.indexBuildingState(for: userID)
        router.navigateToDownloadedMessages(userID: userID, state: state)
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

    var searchIndexDownloadProgress: EncryptedSearchDownloadProgress? {
        dependencies.esService.indexBuildingEstimatedProgress(for: userID)?.toEncryptedSearchDownloadProgress()
    }

    var downloadedMessagesInfo: EncryptedSearchDownloadedMessagesInfo {
        var indexSize: String = "-"
        if let bytes = dependencies.esService.indexSize(for: userID) {
            indexSize = bytes.toByteCount
        }
        var oldestTime: String = "-"
        if let time = dependencies.esService.oldesMessageTime(for: userID) {
            oldestTime = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
        }
        let isDownloadComplete = dependencies.esService.indexBuildingState(for: userID) == .complete
        return .init(isDownloadComplete: isDownloadComplete, indexSize: indexSize, oldesMessageTime: oldestTime)
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
        let locale: Locale
        let timeZone: TimeZone

        init(
            userID: UserID,
            esUserCache: EncryptedSearchUserCache = sharedServices.get(by: EncryptedSearchUserDefaultCache.self),
            esService: EncryptedSearchServiceProtocol = EncryptedSearchService.shared,
            locale: Locale = .current,
            timeZone: TimeZone = .current
        ) {
            self.userID = userID
            self.esUserCache = esUserCache
            self.esService = esService
            self.locale = locale
            self.timeZone = timeZone
        }
    }
}
