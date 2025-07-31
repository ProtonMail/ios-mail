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

extension EventError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason, .other:
            L10n.EventLoopError.eventSyncingError.string
        }
    }
}

extension DraftUndoSendError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            return reason.errorMessage.string
        case .other(let protonError):
            return protonError.errorDescription
        }
    }
}

private extension DraftUndoSendErrorReason {

    var errorMessage: LocalizedStringResource {
        switch self {
        case .messageCanNotBeUndoSent, .sendCanNoLongerBeUndone:
            L10n.Action.UndoSendError.sendCannotBeUndone
        case .messageIsNotADraft, .messageDoesNotExist:
            L10n.Action.UndoSendError.draftNotFound
        }
    }
}

extension DraftCancelScheduleSendError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .reason(let reason):
            return reason.errorMessage.string
        case .other(let protonError):
            return protonError.errorDescription
        }
    }
}

extension DraftCancelScheduleSendErrorReason {

    var errorMessage: LocalizedStringResource {
        switch self {
        case .messageDoesNotExist:
            L10n.Action.UndoScheduleSendError.messageDoesNotExist
        case .messageNotScheduled:
            L10n.Action.UndoScheduleSendError.messageNotScheduled
        case .messageAlreadySent:
            L10n.Action.UndoScheduleSendError.messageAlreadySent
        }
    }
}

extension PinSetError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let pinSetErrorReason):
            return pinSetErrorReason.errorMessage.string
        case .other(let protonError):
            return protonError.localizedDescription
        }
    }
}

private extension PinSetErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .tooShort:
            L10n.PINLock.Error.tooShort
        case .tooLong:
            L10n.PINLock.Error.tooLong
        case .malformed:
            L10n.PINLock.Error.malformed
        }
    }
}

extension SnoozeError {

    public var errorDescription: String? {
        switch self {
        case .reason(let snoozeErrorReason):
            snoozeErrorReason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }

}

private extension SnoozeErrorReason {

    var errorMessage: LocalizedStringResource {
        switch self {
        case .snoozeTimeInThePast:
            L10n.Common.save // FIXME: - Will be updated later
        case .invalidSnoozeLocation:
            L10n.Common.save // FIXME: - Will be updated later
        }
    }

}
