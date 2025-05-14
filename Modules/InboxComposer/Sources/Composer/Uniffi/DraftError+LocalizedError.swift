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

extension DraftAttachmentUploadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftAttachmentUploadErrorReason {

    var errorMessage: LocalizedStringResource {
        switch self {
        case .attachmentTooLarge:
            L10n.DraftAttachmentUploadError.attachmentTooLarge
        case .crypto:
            L10n.DraftAttachmentUploadError.crypto
        case .messageAlreadySent:
            L10n.DraftAttachmentUploadError.messageAlreadySent
        case .messageDoesNotExist:
            L10n.DraftAttachmentUploadError.messageDoesNotExist
        case .messageDoesNotExistOnServer:
            L10n.DraftAttachmentUploadError.messageDoesNotExistOnServer
        case .retryInvalidState:
            L10n.DraftAttachmentUploadError.retryInvalidState
        case .tooManyAttachments:
            L10n.DraftAttachmentUploadError.tooManyAttachments
        }
    }
}

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

extension DraftSaveError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftSaveErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .addressDoesNotHavePrimaryKey(let value):
            L10n.DraftSaveError.addressDoesNotHavePrimaryKey(address: value)
        case .addressDisabled(let value):
            L10n.DraftSaveError.addressDisabled(address: value)
        case .alreadySent, .messageAlreadySent:
            L10n.DraftSaveError.messageAlreadySent
        case .messageDoesNotExist:
            L10n.DraftSaveError.messageDoesNotExist
        case .messageIsNotADraft:
            L10n.DraftSaveError.messageIsNotADraft
        case .recipientEmailInvalid(let value):
            L10n.DraftSaveError.recipientInvalidAddress(address: value)
        case .protonRecipientDoesNotExist(let value):
            L10n.DraftSaveError.protonRecipientNotFound(address: value)
        case .unknownRecipientValidationError(let value):
            L10n.DraftSaveError.unknownRecipientValidation(address: value)
        }
    }
}

extension DraftSendError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

extension DraftSendFailure: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .save(let draftSaveErrorReason):
            draftSaveErrorReason.errorMessage.string
        case .send(let draftSendErrorReason):
            draftSendErrorReason.errorMessage.string
        case .attachmentUpload(let draftAttachmentUploadErrorReason):
            draftAttachmentUploadErrorReason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftSendErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .addressDoesNotHavePrimaryKey(let value):
            L10n.DraftSendError.addressDoesNotHavePrimaryKey(address: value)
        case .addressDisabled(let value):
            L10n.DraftSendError.addressDisabled(address: value)
        case .alreadySent, .messageAlreadySent:
            L10n.DraftSendError.messageAlreadySent
        case .messageDoesNotExist:
            L10n.DraftSendError.messageDoesNotExist
        case .messageIsNotADraft:
            L10n.DraftSendError.messageIsNotADraft
        case .missingAttachmentUploads:
            L10n.DraftSendError.missingAttachmentUploads
        case .noRecipients:
            L10n.DraftSendError.noRecipients
        case .packageError(let value):
            L10n.DraftSendError.packageError(error: value)
        case .recipientEmailInvalid(let value):
            L10n.DraftSendError.recipientInvalidAddress(address: value)
        case .protonRecipientDoesNotExist(let value):
            L10n.DraftSendError.protonRecipientNotFound(address: value)
        case .scheduleSendExpired:
            L10n.DraftSendError.scheduleSendExpired
        case .unknownRecipientValidationError(let value):
            L10n.DraftSendError.unknownRecipientValidation(address: value)
        }
    }
}
