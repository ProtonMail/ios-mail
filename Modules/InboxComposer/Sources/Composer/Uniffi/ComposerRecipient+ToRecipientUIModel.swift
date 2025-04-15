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

extension ComposerRecipient {
    var singleRecipient: ComposerRecipientSingle? {
        switch self {
        case .single(let single): single
        case .group: nil
        }
    }

    var groupRecipient: ComposerRecipientGroup? {
        switch self {
        case .single: nil
        case .group(let group): group
        }
    }

    var isGroup: Bool {
        switch self {
        case .single: false
        case .group: true
        }
    }

    var isValid: Bool {
        switch self {
        case .single(let single):
            single.validState.isValid
        case .group:
            true
        }
    }
}

private extension ComposerRecipientValidState {

    var isValid: Bool {
        switch self {
        case .valid: true
        case .invalid: false
        case .validating: true  // FIXME: have a validating UI, depends on product decision about lock icons
        }
    }
}

extension Array where Element == ComposerRecipient {

    func allSingleRecipients() -> [ComposerRecipientSingle] {
        compactMap(\.singleRecipient)
    }

    func allGroupRecipients() -> [ComposerRecipientGroup] {
        compactMap(\.groupRecipient)
    }
}
