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

struct ComposerState: Equatable, Copying {
    var toRecipients: RecipientFieldState
    var ccRecipients: RecipientFieldState
    var bccRecipients: RecipientFieldState

    var senderEmail: String
    var subject: String
    var attachments: [DraftAttachmentUIModel]
    var initialBody: String
    var isInitialFocusInBody: Bool

    var editingRecipientsGroup: RecipientGroupType?
    var editingRecipientFieldState: RecipientFieldState? {
        guard let group = editingRecipientsGroup else { return nil }
        return self[keyPath: group.keyPath]
    }

    var isSendAvailable: Bool {
        !toRecipients.recipients.isEmpty // FIXME: Implement final logic
    }

    var alert: AlertModel?

    mutating func overrideRecipientState(for group: RecipientGroupType, perform: (RecipientFieldState) -> RecipientFieldState) {
        let currentValue = self[keyPath: group.keyPath]
        self[keyPath: group.keyPath] = perform(currentValue)
    }

    mutating func updateRecipientState(for group: RecipientGroupType, perform: (inout RecipientFieldState) -> Void) {
        perform(&self[keyPath: group.keyPath])
    }
}

extension ComposerState {

    static var initial: ComposerState {
        .init(
            toRecipients: .initialState(group: .to),
            ccRecipients: .initialState(group: .cc),
            bccRecipients: .initialState(group: .bcc),
            senderEmail: .empty,
            subject: .empty,
            attachments: [],
            initialBody: .empty,
            isInitialFocusInBody: false,
            editingRecipientsGroup: nil
        )
    }
}

private extension RecipientGroupType {

    var keyPath: WritableKeyPath<ComposerState, RecipientFieldState> {
        switch self {
        case .to: \.toRecipients
        case .cc: \.ccRecipients
        case .bcc: \.bccRecipients
        }
    }
}
