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
import UIKit

import struct SwiftUI.Color
import enum proton_app_uniffi.ComposerRecipient

struct RecipientUIModel: Equatable {
    let composerRecipient: ComposerRecipient
    var isSelected: Bool = false

    var type: RecipientType {
        composerRecipient.isGroup ? .group : .single
    }
    var displayName: String {
        switch composerRecipient {
        case .single(let single):
            single.displayName ?? single.address
        case .group(let group):
            group.displayName
        }
    }
    var isValid: Bool {
        composerRecipient.isValid
    }
    var isEncrypted: Bool {
        .productStillToComeWithFinalDecision
    }

    var backgroundColor: UIColor {
        isSelected ? DS.Color.InteractionWeak.pressed.toDynamicUIColor : DS.Color.Background.norm.toDynamicUIColor
    }

    var icon: UIImage? {
        guard isValid else { return UIImage(resource: DS.Icon.icExclamationCircle) }
        switch type {
        case .single:
            return isEncrypted ? UIImage(resource: DS.Icon.icLockFilled) : nil
        case .group:
            return UIImage(resource: DS.Icon.icUsersFilled)
        }
    }

    // FIXME: WIP - pending lock icon colors states and color definition
    var iconTintColor: UIColor {
        guard isValid else { return DS.Color.Notification.error.toDynamicUIColor }
        if type == .group {
            return DS.Color.Notification.success.toDynamicUIColor
        }
        return UIColor(Color(hex: "#239ECE"))
    }

    var textColor: UIColor {
        guard isValid else { return DS.Color.Notification.error.toDynamicUIColor }
        return DS.Color.Text.norm.toDynamicUIColor
    }

    var borderColor: UIColor {
        guard isValid else { return DS.Color.Notification.error.toDynamicUIColor }
        return DS.Color.Border.strong.toDynamicUIColor
    }
}

enum RecipientType {
    case single
    case group
}

extension Array where Element == RecipientUIModel {
    var noneIsSelected: Bool {
        filter(\.isSelected).isEmpty
    }

    var selectedIndexes: Set<Int> {
        Set(enumerated().filter(\.element.isSelected).map(\.offset))
    }

    func hasNewDoesNotExistAddressError(comparedTo oldArray: [RecipientUIModel]) -> Bool {
        func extractAddressesThatDoNotExist(from array: [RecipientUIModel]) -> Set<String> {
            Set(
                array.compactMap { model in
                    if case .single(let singleRecipient) = model.composerRecipient,
                        case .invalid(.doesNotExist) = singleRecipient.validState
                    {
                        return singleRecipient.address
                    }
                    return nil
                })
        }
        let oldInvalidAddresses = extractAddressesThatDoNotExist(from: oldArray)
        let newInvalidAddresses = extractAddressesThatDoNotExist(from: self)
        return !newInvalidAddresses.subtracting(oldInvalidAddresses).isEmpty
    }
}

private extension Bool {
    static var productStillToComeWithFinalDecision: Bool { false }
}
