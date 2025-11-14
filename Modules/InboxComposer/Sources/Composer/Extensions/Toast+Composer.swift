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
import InboxCore
import ProtonUIFoundations

public extension Toast {

    static func draftSaved(messageId: ID, undoAction: @escaping (_ messageId: ID) async -> Void) -> Toast {
        let discardButton = Toast.Button(
            type: .smallTrailing(content: .title(L10n.Composer.discard.string)),
            action: { Task { await undoAction(messageId) } }
        )
        return Toast(
            title: nil,
            message: L10n.Composer.draftSaved.string,
            button: discardButton,
            style: .information,
            duration: .short
        )
    }

    static func draftDiscarded() -> Toast {
        .information(message: L10n.Composer.discarded.string)
    }

    static func schedulingMessage(duration: Toast.Duration) -> Toast {
        .information(message: L10n.Composer.schedulingMessage.string, duration: duration)
    }

    static func scheduledMessage(duration: Toast.Duration, scheduledTime: String, undoAction: (() -> Void)?) -> Toast {
        .informationUndo(
            message: L10n.Composer.messageWillBeSentOn(time: scheduledTime).string,
            duration: duration,
            undoAction: undoAction
        )
    }

    static func sendingMessage(duration: Toast.Duration) -> Toast {
        .information(message: L10n.Composer.sendingMessage.string, duration: duration)
    }

    static func messageSent(duration: Toast.Duration, undoAction: (() -> Void)?) -> Toast {
        .informationUndo(
            message: L10n.Composer.messageSent.string,
            duration: duration,
            undoAction: undoAction
        )
    }

    static func messageSentWithoutUndo(duration: Toast.Duration) -> Toast {
        .information(message: L10n.Composer.messageSent.string, duration: duration)
    }
}
