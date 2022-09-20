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

class SettingsLocalStorageViewModel {
    enum SettingsSection: Int {
        case cachedData = 0
        case attachments = 1
        case downloadedMessages = 2

        var title: String {
            switch self {
            case .cachedData:
                return LocalString._settings_title_of_cached_data
            case .attachments:
                return LocalString._settings_title_of_attachments
            case .downloadedMessages:
                return LocalString._settings_title_of_downloaded_messages_local_storage
            }
        }

        var foot: String {
            switch self {
            case .cachedData:
                return ""
            case .attachments:
                return ""
            case .downloadedMessages:
                return LocalString._settings_foot_of_downloaded_messages_local_storage
            }
        }
    }

    init() {
        self.areAttachmentsDeleted.value = false
        self.isCachedDataDeleted.value = false
    }

    var sections: [SettingsSection] = [.cachedData, .attachments, .downloadedMessages]

    var areAttachmentsDeleted = Bindable<Bool>()
    var isCachedDataDeleted = Bindable<Bool>()
}
