//
//  MessageViewActionSheetViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

struct MessageViewActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    init(title: String,
         labelID: String,
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
                break
            case .dark:
                items.append(.viewInLightMode)
            }
        }

        if labelID != Message.Location.trash.rawValue {
            items.append(.trash)
        }

        if ![Message.Location.archive.rawValue, Message.Location.spam.rawValue].contains(labelID) {
            items.append(.archive)
        }

        if labelID == Message.Location.archive.rawValue || labelID == Message.Location.trash.rawValue {
            items.append(.inbox)
        }

        if labelID == Message.Location.spam.rawValue {
            items.append(.spamMoveToInbox)
        }

        let foldersContainsDeleteAction = [
            Message.Location.draft.rawValue,
            Message.Location.sent.rawValue,
            Message.Location.spam.rawValue,
            Message.Location.trash.rawValue
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
