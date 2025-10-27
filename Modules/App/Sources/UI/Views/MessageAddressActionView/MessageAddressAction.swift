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

import DeveloperToolsSupport
import Foundation
import InboxDesignSystem
import SwiftUI

/**
 List of all actions that can take place over an email address (e.g. the sender or a recipient of a message
 */
enum MessageAddressAction: ActionPickerListElement {
    case newMessage
    case call
    case addToContacts
    case blockAddress
    case unblockAddress
    case copyAddress
    case copyName

    var name: LocalizedStringResource {
        switch self {
        case .newMessage:
            L10n.Action.Address.newMessage
        case .call:
            L10n.Action.Address.call
        case .addToContacts:
            L10n.Action.Address.addToContacts
        case .blockAddress:
            L10n.Action.Address.blockAddress
        case .unblockAddress:
            L10n.Action.Address.unblockAddress
        case .copyAddress:
            L10n.Action.Address.copyAddress
        case .copyName:
            L10n.Action.Address.copyName
        }
    }

    var icon: Image {
        imageResource.image
    }

    // MARK: - Private

    private var imageResource: ImageResource {
        switch self {
        case .newMessage:
            DS.Icon.icPenSquare
        case .call:
            DS.Icon.icPhone
        case .addToContacts:
            DS.Icon.icUserPlus
        case .blockAddress, .unblockAddress:
            DS.Icon.icCircleSlash
        case .copyAddress, .copyName:
            DS.Icon.icSquares
        }
    }
}
