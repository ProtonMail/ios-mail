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

import UIKit

enum MailShortcutItem: String, CaseIterable {
    case search
    case starred
    case compose

    var title: LocalizedStringResource {
        switch self {
        case .search:
            L10n.Search.searchPlaceholder
        case .starred:
            L10n.Mailbox.SystemFolder.starred
        case .compose:
            L10n.Mailbox.compose
        }
    }

    var icon: UIApplicationShortcutIcon {
        switch self {
        case .search:
            return .init(type: .search)
        case .starred:
            return .init(type: .favorite)
        case .compose:
            return .init(type: .compose)
        }
    }
}

extension MailShortcutItem {
    static let UserInfoDeepLinkKey = "MailShortcutItem.DeepLink"
}
