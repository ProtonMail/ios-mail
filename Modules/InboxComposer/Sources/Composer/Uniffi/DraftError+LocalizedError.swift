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
        case .attachmentTooLarge, .totalAttachmentSizeTooLarge:
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
        case .timeout:
            L10n.DraftAttachmentUploadError.timeout
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
            L10n.DraftAttachmentUploadError.messageDoesNotExist
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
        case .addressDoesNotHavePrimaryKey:
            L10n.DraftSaveError.addressDoesNotHavePrimaryKey
        case .addressDisabled(let value):
            L10n.DraftSaveError.addressDisabled(address: value)
        case .messageAlreadySent:
            L10n.DraftSaveError.messageAlreadySent
        case .messageDoesNotExist:
            L10n.DraftSaveError.messageDoesNotExist
        case .messageIsNotADraft:
            L10n.DraftSaveError.messageIsNotADraft
        case .recipientEmailInvalid:
            L10n.DraftSaveError.recipientInvalidAddress
        case .protonRecipientDoesNotExist:
            L10n.DraftSaveError.protonRecipientNotFound
        }
    }
}

extension DraftPasswordError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

extension DraftPasswordErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .passwordTooShort:
            L10n.DraftPasswordError.passwordTooShort
        }
    }
}

extension DraftExpirationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

extension DraftExpirationErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .expirationTimeInThePast:
            L10n.DraftExpirationError.expirationTimeInThePast
        case .expirationTimeExceeds30Days:
            L10n.DraftExpirationError.expirationTimeExceeds30Days
        case .expirationTimeLessThan15Min:
            L10n.DraftSendError.expirationTimeTooSoon
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
        case .packageError:
            L10n.DraftSendError.packageError
        case .recipientEmailInvalid(let value):
            L10n.DraftSendError.recipientInvalidAddress(address: value)
        case .protonRecipientDoesNotExist(let value):
            L10n.DraftSendError.protonRecipientNotFound(address: value)
        case .scheduleSendExpired:
            L10n.DraftSendError.scheduleSendExpired
        case .scheduleSendMessageLimitExceeded:
            L10n.DraftSendError.scheduleSendMessageLimitExceeded
        case .eoPasswordDecrypt:
            L10n.DraftSendError.failedToDecryptExternalEncryptionPassword
        case .expirationTimeTooSoon:
            L10n.DraftSendError.expirationTimeTooSoon
        }
    }
}

extension DraftSenderAddressChangeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            reason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftSenderAddressChangeErrorReason {

    var errorMessage: LocalizedStringResource {
        switch self {
        case .addressEmailNotFound:
            L10n.DraftSenderAddressChangeError.addressEmailNotFound
        case .addressNotSendEnabled:
            L10n.DraftSenderAddressChangeError.addressNotSendEnabled
        case .addressDisabled:
            L10n.DraftSenderAddressChangeError.addressDisabled
        }
    }
}
