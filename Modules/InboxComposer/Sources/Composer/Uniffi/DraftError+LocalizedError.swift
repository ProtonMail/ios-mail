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

extension DraftDiscardError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage?.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

extension DraftDiscardErrorReason {
    var errorMessage: LocalizedStringResource? {
        switch self {
        case .messageDoesNotExist:
            nil
        case .deleteFailed:
            L10n.ComposerError.draftDiscardFailed
        }
    }
}

extension DraftOpenError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftOpenErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .addressNotFound:
            L10n.OpenDraftError.addressNotFound
        case .messageBodyMissing:
            L10n.OpenDraftError.missingMessageBody
        case .messageDoesNotExist, .messageIsNotADraft:
            L10n.OpenDraftError.draftDoesNotExist
        case .replyOrForwardDraft:
            L10n.OpenDraftError.cantReplyOrForward
        }
    }
}

extension DraftSaveSendError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftSaveSendErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .addressDoesNotHavePrimaryKey(let value):
            L10n.DraftSaveSendError.addressDoesNotHavePrimaryKey(address: value)
        case .addressDisabled(let value):
            L10n.DraftSaveSendError.addressDisabled(address: value)
        case .alreadySent, .messageAlreadySent:
            L10n.DraftSaveSendError.messageAlreadySent
        case .messageDoesNotExist:
            L10n.DraftSaveSendError.messageDoesNotExist
        case .messageIsNotADraft:
            L10n.DraftSaveSendError.messageIsNotADraft
        case .noRecipients:
            L10n.DraftSaveSendError.noRecipients
        case .packageError(let value):
            L10n.DraftSaveSendError.packageError(error: value)
        case .recipientEmailInvalid(let value):
            L10n.DraftSaveSendError.recipientInvalidAddress(address: value)
        case .protonRecipientDoesNotExist(let value):
            L10n.DraftSaveSendError.protonRecipientNotFound(address: value)
        case .unknownRecipientValidationError(let value):
            L10n.DraftSaveSendError.unknownRecipientValidation(address: value)
        }
    }
}
