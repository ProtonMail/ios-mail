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

    static func unstarActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_unstar_action_for_messages_in_action_sheet :
            LocalString._title_of_unstar_action_for_single_message_in_action_sheet
        return .init(type: .unstar, title: String(format: title, number), icon: Asset.actionSheetStar.image)
    }

    static func starActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_star_action_for_messages_in_action_sheet :
            LocalString._title_of_star_action_for_single_message_in_action_sheet
        return .init(type: .star, title: String(format: title, number), icon: Asset.actionSheetStar.image)
    }

    static func markReadActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_read_action_for_messages_in_action_sheet :
            LocalString._title_of_read_action_for_single_message_in_action_sheet
        return .init(type: .markRead, title: String(format: title, number), icon: Asset.actionSheetRead.image)
    }

    static func markUnreadActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_unread_action_for_messages_in_action_sheet :
            LocalString._title_of_unread_action_for_single_message_in_action_sheet
        return .init(type: .markUnread, title: String(format: title, number), icon: Asset.actionSheetUnread.image)
    }

    static func moveToArchive(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_archive_action_for_messages_in_action_sheet :
            LocalString._title_of_archive_action_for_single_message_in_action_sheet
        return .init(type: .moveToArchive, title: String(format: title, number), icon: Asset.actionSheetArchive.image)
    }

    static func moveToSpam(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_spam_action_for_messages_in_action_sheet :
            LocalString._title_of_spam_action_for_single_message_in_action_sheet
        return .init(type: .moveToSpam, title: String(format: title, number), icon: Asset.actionSheetSpam.image)
    }

    static func removeActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_remove_action_for_messages_in_action_sheet :
            LocalString._title_of_remove_action_for_single_message_in_action_sheet
        return .init(type: .remove, title: String(format: title, number), icon: Asset.actionSheetTrash.image)
    }

    static func deleteActionViewModel(number: Int) -> MailListActionSheetItemViewModel {
        let title = number > 1 ?
            LocalString._title_of_delete_action_for_messages_in_action_sheet :
            LocalString._title_of_delete_action_for_single_message_in_action_sheet
        return .init(type: .delete, title: String(format: title, number), icon: Asset.actionSheetTrash.image)
    }

}
