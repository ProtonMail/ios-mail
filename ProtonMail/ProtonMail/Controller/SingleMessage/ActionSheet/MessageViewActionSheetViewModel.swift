//
//  MessageViewActionSheetViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

struct MessageViewActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    init(title: String,
         labelID: LabelID,
         includeStarring: Bool,
         isStarred: Bool,
         isBodyDecryptable: Bool,
         hasMoreThanOneRecipient: Bool,
         messageRenderStyle: MessageRenderStyle,
         shouldShowRenderModeOption: Bool
    ) {
        self.title = title

        items.append(.reply)
        if hasMoreThanOneRecipient {
            items.append(.replyAll)
        }
        items.append(.forward)

        items.append(contentsOf: [
            .markUnread,
            .labelAs
        ])

        if includeStarring {
            items.append(isStarred ? .unstar : .star)
        }

        if shouldShowRenderModeOption {
            switch messageRenderStyle {
            case .lightOnly:
                items.append(.viewInDarkMode)
            case .dark:
                items.append(.viewInLightMode)
            }
        }

        if labelID != Message.Location.trash.labelID {
            items.append(.trash)
        }

        if ![Message.Location.archive.labelID, Message.Location.spam.labelID].contains(labelID) {
            items.append(.archive)
        }

        if labelID == Message.Location.archive.labelID || labelID == Message.Location.trash.labelID {
            items.append(.inbox)
        }

        if labelID == Message.Location.spam.labelID {
            items.append(.spamMoveToInbox)
        }

        let foldersContainsDeleteAction = [
            Message.Location.draft.labelID,
            Message.Location.sent.labelID,
            Message.Location.spam.labelID,
            Message.Location.trash.labelID
        ]
        if foldersContainsDeleteAction.contains(labelID) {
            items.append(.delete)
        } else {
            items.append(.spam)
        }

        items.append(contentsOf: [
            .moveTo,
            .print,
            .viewHeaders
        ])

        if isBodyDecryptable {
            items.append(.viewHTML)
        }

        items.append(.reportPhishing)
    }
}
