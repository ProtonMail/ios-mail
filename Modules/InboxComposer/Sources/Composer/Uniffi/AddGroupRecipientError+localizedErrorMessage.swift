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

import proton_app_uniffi
import Foundation

extension AddGroupRecipientError {

    func localizedErrorMessage() -> LocalizedStringResource? {
        switch self {
        case .ok, .emptyGroupName:
            return nil
        case .duplicate(let duplicateAddresses):
            guard !duplicateAddresses.isEmpty else { return nil }
            let duplicates = duplicateAddresses.joined(separator: ", ")
            return duplicateAddresses.count > 1
                ? L10n.ComposerError.duplicateRecipients(addresses: duplicates)
                : L10n.ComposerError.duplicateRecipient(address: duplicates)
        case .saveFailed, .other:
            return L10n.ComposerError.draftSaveFailed
        }
    }
}
