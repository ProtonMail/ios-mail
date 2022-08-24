// Copyright (c) 2022 Proton AG
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

import XCTest
import pmtest

fileprivate struct id {

    /// Expiration picker identifiers.
    static let expirationPickerIdentifier = "ExpirationPickerCell.picker"
    static let expirationActionButtonIdentifier = "expirationActionButton"

    /// Expiration picker identifiers.
    static let saveDraftButtonText = "saveDraftButton"
    static let invalidAddressStaticTextIdentifier = LocalString._signle_address_invalid_error_content
    static let recipientNotFoundStaticTextIdentifier = LocalString._recipient_not_found
    
    static let setExpirationButtonLabel = LocalString._general_set
}

enum expirationPeriod: String {
    case oneHour = "1 hour"
    case oneDay = "1 day"
    case threeDaays = "3 days"
    case oneWeek = "1 week"
    case custom = ""
}

/**
 Class represents Message Expiration dialog.
 */
class MessageExpirationRobot: CoreElements {
    @discardableResult
    func setExpiration(_ period: expirationPeriod) -> ComposerRobot {
        return selectExpirationPeriod(period).setPeriod()
    }

    private func selectExpirationPeriod(_ period: expirationPeriod) -> MessageExpirationRobot {
        staticText(period.rawValue).tap()
        return MessageExpirationRobot()
    }
    
    private func setPeriod() -> ComposerRobot {
        button(id.setExpirationButtonLabel).tap()
        return ComposerRobot()
    }
}

