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

import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct MailboxBarsState: Equatable {
    var visibilityMode: TopBarVisibilityMode = .regular
    var unreadButtonState: UnreadButtonState = .init(isSelected: false, counterState: .unknown)
    var selectAll: SelectAllState = .canSelectMoreItems
    var spamTrashToggleState: SpamTrashToggleState = .hidden
}

enum TopBarVisibilityMode: Equatable {
    case regular
    case selectionMode
}

enum SelectAllState: Equatable {
    struct ButtonStyle: Equatable {
        let icon: SFSymbol
        let iconColor: Color
        let text: LocalizedStringResource
        let textColor: Color
    }

    case canSelectMoreItems
    case noMoreItemsToSelect
    case selectionLimitReached

    var button: ButtonStyle {
        let symbol: SFSymbol
        let text: LocalizedStringResource

        switch self {
        case .canSelectMoreItems:
            symbol = .square
            text = L10n.Mailbox.selectAll
        case .noMoreItemsToSelect, .selectionLimitReached:
            symbol = .checkmarkSquare
            text = L10n.Mailbox.unselectAll
        }

        return .init(icon: symbol, iconColor: DS.Color.Icon.norm, text: text, textColor: DS.Color.Text.norm)
    }
}

enum SpamTrashToggleState: Equatable {
    case visible(isSelected: Bool)
    case hidden
}

extension SpamTrashToggleState {
    func toggled() -> Self {
        if case .visible(let isSelected) = self {
            .visible(isSelected: !isSelected)
        } else {
            .hidden
        }
    }

    var isSelected: Bool {
        switch self {
        case .visible(let isSelected):
            isSelected
        case .hidden:
            false
        }
    }

    var includeSpamTrash: IncludeSwitch {
        isSelected ? .withSpamAndTrash : .default
    }

    var systemLabel: SystemLabel {
        switch self {
        case .visible(let isSelected):
            isSelected ? .allMail : .almostAllMail
        case .hidden:
            .allMail
        }
    }
}
