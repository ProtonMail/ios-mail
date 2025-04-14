// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore

struct EmptyFolderBanner {
    enum ActionButton: Equatable {
        case upgradePlan
        case emptyLocation
    }
    
    struct FolderDetails {
        let labelID: ID
        let type: Folder
    }
    
    enum Folder {
        case spam
        case trash
        
        var humanReadable: String {
            switch self {
            case .spam:
                L10n.Mailbox.SystemFolder.spam.string
            case .trash:
                L10n.Mailbox.SystemFolder.trash.string
            }
        }
    }

    enum UserState {
        case freePlan
        case paidAutoDeleteOn
        case paidAutoDeleteOff
    }

    let folder: FolderDetails
    let userState: UserState
}
