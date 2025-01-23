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

import Foundation
import proton_app_uniffi

extension DraftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let draftErrorReason):
            draftErrorReason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftErrorReason {
    var errorMessage: LocalizedStringResource {
        temporaryDescription.stringResource
    }

    // TODO: Pending adding more granularity to DraftError to have more context and decide the copy to show the user
    var temporaryDescription: String {
        switch self {
        case .noRecipients:
            "no recipients"
        case .addressDoesNotHavePrimaryKey(let string):
            "primary key for address missing: \(string)"
        case .recipientEmailInvalid(let string):
            "recipient email invalid: \(string)"
        case .protonRecipientDoesNotExist(let string):
            "proton recipient does not exist: \(string)"
        case .unknownRecipientValidationError(let string):
            "unknown recipient: \(string)"
        case .addressDisabled(let string):
            "address disabled: \(string)"
        case .messageAlreadySent:
            "message already exists"
        case .packageError(let string):
            "package error: \(string)"
        case .messageUpdateIsNotDraft:
            "message update is not a draft"
        case .messageDoesNotExist:
            "message does not exist"
        case .alreadySent:
            "message has already been sent"
        case .messageCanNotBeUndoSent:
            "message can't undo send"
        case .sendCanNoLongerBeUndone:
            "send cannot longer be undone"
        }
    }
}
