// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

class SettingsEncryptedSearchDownloadedMessagesViewModel {
    enum SettingsSection: Int {
        case messageHistory = 0
        case storageLimit = 1
        case storageUsage = 2
        
        var title: String {
            switch self {
            case .messageHistory:
                return LocalString._settings_title_of_message_history
            case .storageLimit:
                return LocalString._settings_title_of_storage_limit
            case .storageUsage:
                return LocalString._settings_title_of_storage_usage
            }
        }
        var foot: String {
            switch self {
            case .messageHistory:
                return ""
            case .storageLimit:
                return ""
            case .storageUsage:
                return LocalString._encrypted_search_downloaded_messages_explanation
            }
        }
    }
    
    private var encryptedSearchDownloadedMessagesCache: EncryptedSearchDownloadedMessagesCacheProtocol
    
    init(encryptedSearchDownloadedMessagesCache: EncryptedSearchDownloadedMessagesCacheProtocol) {
        self.encryptedSearchDownloadedMessagesCache = encryptedSearchDownloadedMessagesCache
    }

    var storageLimit: Int64 {
        get {
            return encryptedSearchDownloadedMessagesCache.storageLimit
        }
        set {
            encryptedSearchDownloadedMessagesCache.storageLimit = newValue
        }
    }
    
    var sections: [SettingsSection] = [.messageHistory, .storageLimit, .storageUsage]
}
