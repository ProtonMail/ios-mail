//
//  MessageViewActionSheetAction.swift
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

import ProtonCore_UIFoundations

enum MessageViewActionSheetAction: Equatable, ToolbarAction {
    case archive
    case delete
    case dismiss
    case forward
    case inbox
    case labelAs
    case markRead
    case markUnread
    case moveTo
    case print
    case reply
    case replyAll
    case reportPhishing
    case saveAsPDF
    case spam
    case spamMoveToInbox
    case star
    case trash
    case unstar
    case viewHeaders
    case viewHTML
    case viewInDarkMode
    case viewInLightMode
    case toolbarCustomization
    case more
    case replyOrReplyAll

    var title: String? {
        switch self {
        case .archive:
            return L11n.PushNotificationAction.archive
        case .reply:
            return LocalString._action_sheet_action_title_reply
        case .replyAll:
            return LocalString._action_sheet_action_title_replyAll
        case .forward:
            return LocalString._action_sheet_action_title_forward
        case .markUnread:
            return LocalString._title_of_unread_action_in_action_sheet
        case .markRead:
            return LocalString._title_of_read_action_in_action_sheet
        case .labelAs:
            return LocalString._action_sheet_action_title_labelAs
        case .trash:
            return LocalString._action_sheet_action_title_trash
        case .spam:
            return LocalString._action_sheet_action_title_spam
        case .delete:
            return LocalString._action_sheet_action_title_delete
        case .moveTo:
            return LocalString._action_sheet_action_title_moveTo
        case .print:
            return LocalString._action_sheet_action_title_print
        case .saveAsPDF:
            return LocalString._action_sheet_action_title_saveAsPDF
        case .viewHeaders:
            return LocalString._action_sheet_action_title_view_headers
        case .viewHTML:
            return LocalString._action_sheet_action_title_view_html
        case .reportPhishing:
            return LocalString._action_sheet_action_title_phishing
        case .dismiss:
            return nil
        case .inbox:
            return LocalString._action_sheet_action_title_inbox
        case .spamMoveToInbox:
            return LocalString._action_sheet_action_title_spam_to_inbox
        case .star:
            return LocalString._title_of_star_action_in_action_sheet
        case .unstar:
            return LocalString._title_of_unstar_action_in_action_sheet
        case .viewInLightMode:
            return LocalString._title_of_viewInLightMode_action_in_action_sheet
        case .viewInDarkMode:
            return LocalString._title_of_viewInDarkMode_action_in_action_sheet
        case .toolbarCustomization:
            return LocalString._toolbar_customize_general_title
        case .more:
            return nil
        case .replyOrReplyAll:
            return LocalString._action_sheet_action_title_reply
        }
    }

    var icon: UIImage? {
        switch self {
        case .reply:
            return IconProvider.reply
        case .replyAll:
            return IconProvider.replyAll
        case .forward:
            return IconProvider.forward
        case .markUnread:
            return IconProvider.envelopeDot
        case .markRead:
            return IconProvider.envelope
        case .labelAs:
            return IconProvider.tag
        case .trash:
            return IconProvider.trash
        case .archive:
            return IconProvider.archiveBox
        case .spam:
            return IconProvider.fire
        case .delete:
            return IconProvider.trashCross
        case .moveTo:
            return IconProvider.folderArrowIn
        case .print:
            return IconProvider.printer
        case .saveAsPDF:
            return IconProvider.filePdf
        case .viewHeaders:
            return IconProvider.fileLines
        case .viewHTML:
            return IconProvider.code
        case .reportPhishing:
            return IconProvider.hook
        case .dismiss:
            return IconProvider.cross
        case .inbox, .spamMoveToInbox:
            return IconProvider.inbox
        case .star:
            return IconProvider.star
        case .unstar:
            return IconProvider.starSlash
        case .viewInLightMode:
            return IconProvider.sun
        case .viewInDarkMode:
            return IconProvider.moon
        case .toolbarCustomization:
            return Asset.icMagicWand.image
        case .more:
            return IconProvider.threeDotsHorizontal
        case .replyOrReplyAll:
            return IconProvider.arrowUpAndLeft
        }
    }

    var group: MessageViewActionSheetGroup {
        switch self {
        case .archive, .trash, .spam, .delete, .moveTo, .inbox, .spamMoveToInbox:
            return .moveMessage
        case .reply, .replyAll, .forward, .replyOrReplyAll:
            return .messageActions
        case .markUnread, .markRead, .labelAs, .star, .unstar, .viewInLightMode, .viewInDarkMode:
            return .manage
        case .print, .saveAsPDF, .viewHeaders, .viewHTML, .reportPhishing, .toolbarCustomization:
            return .more
        case .dismiss, .more:
            return .noGroup
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .delete:
            return "PMToolBarView.deleteButton"
        case .trash:
            return "PMToolBarView.trashButton"
        case .moveTo:
            return "PMToolBarView.moveToButton"
        case .more:
            return "PMToolBarView.moreButton"
        case .labelAs:
            return "PMToolBarView.labelAsButton"
        case .markRead:
            return "PMToolBarView.readButton"
        case .markUnread:
            return "PMToolBarView.unreadButton"
        default:
            return title ?? ""
        }
    }
}

// MARK: - Static
extension MessageViewActionSheetAction {
    static let actionsNotAddableToToolbar: [MessageViewActionSheetAction] = [
        .reply,
        .replyAll,
        .dismiss,
        .more,
        .toolbarCustomization,
        .viewInDarkMode,
        .viewInLightMode
    ]

    static let defaultActions: [Self] = [
        .markUnread,
        .trash,
        .moveTo,
        .labelAs
    ]

    static func allActionsOfListView() -> [Self] {
        return [
            .star,
            .markUnread,
            .labelAs,
            .trash,
            .archive,
            .spam,
            .moveTo
        ]
    }

    static func allActionsOfConversationView() -> [Self] {
        return [
            .markUnread,
            .star,
            .labelAs,
            .trash,
            .archive,
            .spam,
            .moveTo
        ]
    }

    static func allActionsOfMessageView() -> [Self] {
        return [
            .reply,
            .forward,
            .markUnread,
            .labelAs,
            .star,
            .viewInLightMode,
            .trash,
            .archive,
            .spam,
            .moveTo,
            .saveAsPDF,
            .print,
            .viewHeaders,
            .viewHTML,
            .reportPhishing
        ]
    }
}

extension MessageViewActionSheetAction {
    static func convert(from: [ServerToolbarAction]) -> [MessageViewActionSheetAction] {
        return from.compactMap { action in
            switch action {
            case .replyOrReplyAll:
                return .replyOrReplyAll
            case .markAsReadOrUnread:
                return .markUnread
            case .starOrUnstar:
                return .star
            case .forward:
                return .forward
            case .labelAs:
                return .labelAs
            case .moveTo:
                return .moveTo
            case .moveToTrash:
                return .trash
            case .moveToArchive:
                return .archive
            case .moveToSpam:
                return .spam
            case .viewMessageInLight:
                return .viewInLightMode
            case .print:
                return .print
            case .viewHeader:
                return .viewHeaders
            case .viewHTML:
                return .viewHTML
            case .reportPhishing:
                return .reportPhishing
            case .remindMe:
                return nil
            case .saveAsPDF:
                return .saveAsPDF
            case .emailsForSender:
                return nil
            case .downloadAttachments:
                return nil
            }
        }
    }
}

extension Array where Element == MessageViewActionSheetAction {
    private func replaceTrashActionWithDeleteAction() -> Self {
        var actions = self
        if let index = actions.firstIndex(of: .trash) {
            actions.remove(at: index)
            actions.insert(.delete, at: index)
        }
        return actions
    }

    func replaceDeleteActionWithTrashAction() -> Self {
        var actions = self
        if let index = actions.firstIndex(of: .delete) {
            actions.remove(at: index)
            actions.insert(.trash, at: index)
        }
        return actions
    }

    func addMoreActionToTheLastLocation() -> Self {
        var newActions = self
        newActions.removeAll(where: { $0 == .more })
        newActions.append(.more)
        return newActions
    }

    func removeMoreAction() -> Self {
        var newActions = self
        newActions.removeAll(where: { $0 == .more })
        return newActions
    }

    func replaceCorrectStarAction(isAnyStarMessages: Bool) -> Self {
        var newActions = self
        if isAnyStarMessages {
            if let index = newActions.firstIndex(where: { $0 == .star }) {
                if !newActions.contains(.unstar) {
                    newActions[index] = .unstar
                }
                newActions.removeAll(where: { $0 == .star })
            }
        } else {
            if let index = newActions.firstIndex(where: { $0 == .unstar }) {
                if !newActions.contains(.star) {
                    newActions[index] = .star
                }
                newActions.removeAll(where: { $0 == .unstar })
            }
        }
        return newActions
    }

    func replaceCorrectUnreadAction(isAnyMessageRead: Bool) -> Self {
        var newActions = self
        if isAnyMessageRead {
            if let index = newActions.firstIndex(where: { $0 == .markRead }) {
                if !newActions.contains(.markUnread) {
                    newActions[index] = .markUnread
                }
                newActions.removeAll(where: { $0 == .markRead })
            }
        } else {
            if let index = newActions.firstIndex(where: { $0 == .markUnread }) {
                if !newActions.contains(.markRead) {
                    newActions[index] = .markRead
                }
                newActions.removeAll(where: { $0 == .markUnread })
            }
        }
        return newActions
    }

    func replaceCorrectMoveToSpamOrInbox(isInSpam: Bool) -> Self {
        var newActions = self
        if isInSpam {
            if let index = newActions.firstIndex(of: .spam) {
                newActions.remove(at: index)
                newActions.insert(.spamMoveToInbox, at: index)
            }
        } else {
            if let index = newActions.firstIndex(of: .spamMoveToInbox) {
                newActions.remove(at: index)
                newActions.insert(.spam, at: index)
            }
        }
        return newActions
    }

    func replaceCorrectTrashOrDeleteAction(isInTrashOrSpam: Bool) -> Self {
        var newActions = self
        if isInTrashOrSpam {
            newActions = newActions.replaceTrashActionWithDeleteAction()
        } else {
            newActions = newActions.replaceDeleteActionWithTrashAction()
        }
        return newActions
    }

    func replaceReplyAndReplyAllAction() -> Self {
        guard !self.contains(.replyOrReplyAll) else {
            return self
        }
        var newActions = self
        newActions.insert(.replyOrReplyAll, at: 0)
        newActions.removeAll(where: { $0 == .reply || $0 == .replyAll })
        return newActions
    }

    func replaceCorrectArchiveAction(isInArchiveOrTrash: Bool) -> Self {
        var newActions = self
        if isInArchiveOrTrash {
            if let index = newActions.firstIndex(where: { $0 == .archive }) {
                if !newActions.contains(.inbox) {
                    newActions[index] = .inbox
                }
                newActions.removeAll(where: { $0 == .archive })
            }
        } else {
            if let index = newActions.firstIndex(where: { $0 == .inbox }) {
                if !newActions.contains(.inbox) {
                    newActions[index] = .archive
                }
                newActions.removeAll(where: { $0 == .inbox })
            }
        }
        return newActions
    }

    func replaceCorrectReplyOrReplyAll(hasMultipleRecipients: Bool) -> Self {
        var newActions = self
        if hasMultipleRecipients {
            if let index = newActions.firstIndex(where: { $0 == .replyOrReplyAll }) {
                newActions[index] = .replyAll
            }
            newActions.removeAll(where: { $0 == .reply || $0 == .replyOrReplyAll })
        } else {
            if let index = newActions.firstIndex(where: { $0 == .replyOrReplyAll }) {
                newActions[index] = .reply
            }
            newActions.removeAll(where: { $0 == .replyAll || $0 == .replyOrReplyAll })
        }
        return newActions
    }
}

enum MessageViewActionSheetGroup: Int {
    case messageActions
    case manage
    case moveMessage
    case more
    case noGroup

    var title: String {
        switch self {
        case .noGroup:
            return ""
        case .messageActions:
            return LocalString._action_sheet_group_title_message_actions
        case .manage:
            return LocalString._action_sheet_group_title_manage
        case .moveMessage:
            return LocalString._action_sheet_group_title_move_message
        case .more:
            return LocalString._action_sheet_group_title_more
        }
    }

    var order: Int {
        rawValue
    }
}
