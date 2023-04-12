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

protocol SettingsEncryptedSearchViewModelProtocol {
    var input: SettingsEncryptedSearchViewModelInput { get }
    var output: SettingsEncryptedSearchViewModelOutput { get }
}

protocol SettingsEncryptedSearchViewModelInput {
    func viewWillAppear()
    func didChangeEncryptedSearchValue(isNewStatusEnabled: Bool)
    func didChangeUseMobileDataValue(isNewStatusEnabled: Bool)
    func didTapDownloadedMessages()
    func didTapPauseMessagesDownload()
    func didTapResumeMessagesDownload()
}

protocol SettingsEncryptedSearchViewModelOutput {
    var sections: [SettingsEncryptedSearchSection] { get }
    var isEncryptedSearchEnabled: Bool { get }
    var isUseMobileDataEnabled: Bool { get }
    var isDownloadInProgress: Bool { get }

    func setUIDelegate(_ delegate: SettingsEncryptedSearchUIProtocol)
}

protocol SettingsEncryptedSearchUIProtocol: AnyObject {
    func reloadData()
    func updateDownloadProgress(progress: EncryptedSearchDownloadProgress)
}

enum SettingsEncryptedSearchSection {
    case encryptedSearchFeature
    case downloadViaMobileData
    case downloadProgress
    case downloadedMessages
}

struct EncryptedSearchDownloadProgress {
    let numMessagesDownloaded: Int
    let totalMessages: Int
    let timeRemaining: String
    let percentageDownloaded: Int
}
