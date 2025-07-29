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

extension AddSingleRecipientError {

    func localizedErrorMessage(entry: SingleRecipientEntry) -> LocalizedStringResource {
        switch self {
        case .ok:
            LocalizedStringResource(stringLiteral: .empty)
        case .duplicate:
            L10n.ComposerError.duplicateRecipient(address: entry.email)
        case .saveFailed:
            L10n.ComposerError.draftSaveFailed
        }
    }
}
