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

extension EncryptedSearchIndexState {

    /// Only some states allow to show downloading progress.
    /// This variable returns `true`
    var allowsToShowDownloadingProgress: Bool {
        switch self {
        case .creatingIndex, .paused, .downloadingNewMessage, .undetermined, .background, .backgroundStopped:
            return true
        case .disabled, .partial, .complete:
            return false
        }
    }

    /// Only some states allow to navigate to extra info for downloaded
    /// messages. This variable returns `true` if such navigation is
    /// allowed.
    var allowsToShowDownloadedMessagesInfo: Bool {
        switch self {
        case .creatingIndex, .partial, .complete, .paused, .downloadingNewMessage, .background, .backgroundStopped:
            return true
        case .disabled, .undetermined:
            return false
        }
    }
}
