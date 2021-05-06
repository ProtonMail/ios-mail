//
//  MailListActionSheetItemViewModel+Actions.swift
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

extension MailListActionSheetItemViewModel {

    static func unstarActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .unstar,
                     title: LocalString._title_of_unstar_action_in_action_sheet,
                     icon: Asset.actionSheetUnstar.image)
    }

    static func starActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .star,
                     title: LocalString._title_of_star_action_in_action_sheet,
                     icon: Asset.actionSheetStar.image)
    }

    static func markReadActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .markRead,
                     title: LocalString._title_of_read_action_in_action_sheet,
                     icon: Asset.actionSheetRead.image)
    }

    static func markUnreadActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .markUnread,
                     title: LocalString._title_of_unread_action_in_action_sheet,
                     icon: Asset.actionSheetUnread.image)
    }

    static func moveToArchive() -> MailListActionSheetItemViewModel {
        return .init(type: .moveToArchive,
                     title: LocalString._title_of_archive_action_in_action_sheet,
                     icon: Asset.actionSheetArchive.image)
    }

    static func moveToSpam() -> MailListActionSheetItemViewModel {
        return .init(type: .moveToSpam,
                     title: LocalString._title_of_spam_action_in_action_sheet,
                     icon: Asset.actionSheetSpam.image)
    }

    static func removeActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .remove,
                     title: LocalString._title_of_remove_action_in_action_sheet,
                     icon: Asset.actionSheetTrash.image)
    }

    static func deleteActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .delete,
                     title: LocalString._title_of_delete_action_in_action_sheet,
                     icon: Asset.actionSheetTrash.image)
    }

    static func labelAsActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .labelAs,
                     title: LocalString._label_as_,
                     icon: Asset.swipeLabelAs.image)
    }

    static func moveToActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .moveTo,
                     title: LocalString._move_to_,
                     icon: Asset.swipeMoveTo.image)
    }

    static func moveToInboxActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .moveToInbox,
                     title: LocalString._title_of_move_inbox_action_in_action_sheet,
                     icon: Asset.menuInbox.image)
    }

    static func notSpamActionViewModel() -> MailListActionSheetItemViewModel {
        return .init(type: .moveToInbox,
                     title: LocalString._action_sheet_action_title_spam_to_inbox,
                     icon: Asset.menuInbox.image)
    }
}
