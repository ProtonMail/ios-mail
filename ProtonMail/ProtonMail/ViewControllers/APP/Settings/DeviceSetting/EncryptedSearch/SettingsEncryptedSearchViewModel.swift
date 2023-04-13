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

    // TODO: read/write from userCacheStatus
    var isEncryptedSearchEnabled: Bool = false

    private(set) var sections: [SettingsEncryptedSearchSection] = [.encryptedSearchFeature]

    init(router: SettingsEncryptedSearchRouterProtocol, dependencies: Dependencies) {
        self.router = router
        self.dependencies = dependencies
    }
}

extension SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelInput {

    func viewWillAppear() {
        // TODO: use the dependencies
    }

    func didChangeEncryptedSearchValue(isNewStatusEnabled: Bool) {
        // TODO: This logic is just for demo purposes
        isEncryptedSearchEnabled = isNewStatusEnabled
        if isNewStatusEnabled {
            sections = [.encryptedSearchFeature, .downloadViaMobileData, .downloadProgress]
        } else {
            sections = [.encryptedSearchFeature]
        }
        uiDelegate?.reloadData()
    }

    func didChangeUseMobileDataValue(isNewStatusEnabled: Bool) {
        // TODO: use the dependencies
    }

    func didTapDownloadedMessages() {
        router.navigateToDownloadedMessages()
    }

    func didTapPauseMessagesDownload() {
        // TODO: use the dependencies
    }

    func didTapResumeMessagesDownload() {
        // TODO: use the dependencies
    }
}

extension SettingsEncryptedSearchViewModel: SettingsEncryptedSearchViewModelOutput {

//    var isEncryptedSearchEnabled: Bool {
//        return true // TODO: use the dependencies
//    }

    var isUseMobileDataEnabled: Bool {
        return true // TODO: use the dependencies
    }

    var isDownloadInProgress: Bool {
        return true // TODO: use the dependencies
    }

    func setUIDelegate(_ delegate: SettingsEncryptedSearchUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension SettingsEncryptedSearchViewModel {

    struct Dependencies {
        // TODO: Add dependencies
    }
}
