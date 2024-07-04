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

/**
 List of all actions that can take place over an email address (e.g. the sender or a recipient of a message
 */
enum MessageAddressAction: ActionPickerListElement {
    case newMessage
    case call
    case addToContacts
    case blockContact
    case copyAddress
    case copyName

    var name: String {
        switch self {
        case .newMessage:
            return LocalizationTemp.MessageAddressAction.newMessage
        case .call:
            return LocalizationTemp.MessageAddressAction.call
        case .addToContacts:
            return LocalizationTemp.MessageAddressAction.addToContacts
        case .blockContact:
            return LocalizationTemp.MessageAddressAction.blockContact
        case .copyAddress:
            return LocalizationTemp.MessageAddressAction.copyAddress
        case .copyName:
            return LocalizationTemp.MessageAddressAction.copyName
        }
    }

    var icon: UIImage {
        switch self {
        case .newMessage:
            return DS.Icon.icPenSquare
        case .call:
            return DS.Icon.icPhone
        case .addToContacts:
            return DS.Icon.icUserPlus
        case .blockContact:
            return DS.Icon.icCircleSlash
        case .copyAddress, .copyName:
            return DS.Icon.icSquares
        }
    }
}
