// Copyright (c) 2024 Proton Technologies AG
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

import DesignSystem
import Foundation
import class SwiftUI.UIImage

enum SystemFolderIdentifier: UInt64 {
    case inbox = 0
    case spam = 4
//    case allMail = 5
//    case archive = 6
    case sent = 7
//    case draft = 8
    case starred = 10
}

extension SystemFolderIdentifier {

    var localisedName: String {
        switch self {
        case .inbox:
            LocalizationTemp.Mailbox.inbox
        case .sent:
            LocalizationTemp.Mailbox.sent
        case .spam:
            LocalizationTemp.Mailbox.spam
        case .starred:
            LocalizationTemp.Mailbox.starred
        }
    }

    var icon: UIImage {
        switch self {
        case .inbox:
            DS.Icon.icInbox
        case .sent:
            DS.Icon.icPaperPlane
        case .spam:
            DS.Icon.icFire
        case .starred:
            DS.Icon.icStar
        }
    }
}
