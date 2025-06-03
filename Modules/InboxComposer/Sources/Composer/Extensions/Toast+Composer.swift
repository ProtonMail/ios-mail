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
import InboxCoreUI

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
            duration: .toastDefaultDuration
        )
    }

    static func draftDiscarded() -> Toast {
        return Toast(
            title: nil,
            message: L10n.Composer.discarded.string,
            button: nil,
            style: .information,
            duration: .toastDefaultDuration
        )
    }

    static func schedulingMessage(duration: TimeInterval) -> Toast {
        Toast(
            title: nil,
            message: L10n.Composer.schedulingMessage.string,
            button: nil,
            style: .information,
            duration: duration
        )
    }

    static func scheduledMessage(duration: TimeInterval, scheduledTime: String, undoAction: (() -> Void)?) -> Toast {
        var undoButton: Button?
        if let undoAction {
            undoButton = .init(type: .smallTrailing(content: .title(L10n.Composer.undoSend.string)), action: undoAction)
        }
        return Toast(
            title: nil,
            message: L10n.Composer.messageWillBeSentOn(time: scheduledTime).string,
            button: undoButton,
            style: .information,
            duration: duration
        )
    }

    static func sendingMessage(duration: TimeInterval) -> Toast {
        Toast(
            title: nil,
            message: L10n.Composer.sendingMessage.string,
            button: nil,
            style: .information,
            duration: duration
        )
    }

    static func messageSent(duration: TimeInterval, undoAction: (() -> Void)?) -> Toast {
        var undoButton: Button?
        if let undoAction {
            undoButton = .init(type: .smallTrailing(content: .title(L10n.Composer.undoSend.string)), action: undoAction)
        }
        return Toast(
            title: nil,
            message: L10n.Composer.messageSent.string,
            button: undoButton,
            style: .information,
            duration: duration
        )
    }

    static func messageSentWithoutUndo(duration: TimeInterval) -> Toast {
        return Toast(
            title: nil,
            message: L10n.Composer.messageSent.string,
            button: nil,
            style: .information,
            duration: duration
        )
    }
}
