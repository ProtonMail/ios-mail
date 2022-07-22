//
//  LabelLocation.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import UIKit
import ProtonCore_UIFoundations

enum LabelLocation: Equatable, Hashable, CaseIterable {
    static var allCases: [LabelLocation] = [
        .provideFeedback,
        .inbox,
        .hiddenDraft,
        .draft,
        .hiddenSent,
        .sent,
        .starred,
        .archive,
        .spam,
        .trash,
        .allmail,
        .customize("", nil),
        .bugs,
        .contacts,
        .settings,
        .signout,
        .lockapp,
        .subscription,
        .addLabel,
        .addFolder,
        .accountManger,
        .addAccount
    ]

    case provideFeedback

    case inbox
    case hiddenDraft // 1 can't be removed
    case draft
    case hiddenSent // 2 can't be removed
    case sent
    case starred
    case archive
    case spam
    case trash
    case allmail
    case customize(String, String?)

    case bugs
    case contacts
    case settings
    case signout
    case lockapp
    case subscription

    case addLabel
    case addFolder
    case accountManger
    case addAccount

    init(labelID: LabelID, name: String?) {
        self.init(id: labelID.rawValue, name: name)
    }
    
    init(id: String, name: String?) {
        switch id {
        case "Provide feedback": self = .provideFeedback
        case "0": self = .inbox
        case "1": self = .hiddenDraft
        case "8": self = .draft
        case "2": self = .hiddenSent
        case "7": self = .sent
        case "10": self = .starred
        case "6": self = .archive
        case "4": self = .spam
        case "3": self = .trash
        case "5": self = .allmail
        case "Report a bug": self = .bugs
        case "Contacts": self = .contacts
        case "Settings": self = .settings
        case "Logout": self = .signout
        case "Lock The App": self = .lockapp
        case "Subscription": self = .subscription
        case "Add Label": self = .addLabel
        case "Add Folder": self = .addFolder
        case "Account Manager": self = .accountManger
        case "Add Account": self = .addAccount
        default:
            if let name = name {
                self = .customize(id, name)
            } else {
                self = .customize(id, nil)
            }
        }
    }
    
    var rawLabelID: String {
        switch self {
        case .provideFeedback: return "Provide feedback"
        case .inbox: return "0"
        case .hiddenDraft: return "1"
        case .draft: return "8"
        case .hiddenSent: return "2"
        case .sent: return "7"
        case .starred: return "10"
        case .archive: return "6"
        case .spam: return "4"
        case .trash: return "3"
        case .allmail: return "5"
        case .customize(let id, _): return id

        case .bugs: return "Report a bug"
        case .contacts: return "Contacts"
        case .settings: return "Settings"
        case .signout: return "Logout"
        case .lockapp: return "Lock The App"
        case .subscription: return "Subscription"

        case .addLabel: return "Add Label"
        case .addFolder: return "Add Folder"
        case .accountManger: return "Account Manager"
        case .addAccount: return "Add Account"
        }
    }

    var labelID: LabelID {
        return LabelID.init(rawValue: rawLabelID)
    }
    
    var localizedTitle: String {
        switch self {
        case .provideFeedback: return LocalString._provide_feedback
        case .inbox: return LocalString._menu_inbox_title
        case .hiddenDraft: return ""
        case .draft: return LocalString._menu_drafts_title
        case .hiddenSent: return ""
        case .sent: return LocalString._menu_sent_title
        case .starred: return LocalString._menu_starred_title
        case .archive: return LocalString._menu_archive_title
        case .spam: return LocalString._menu_spam_title
        case .trash: return LocalString._menu_trash_title
        case .allmail: return LocalString._menu_allmail_title
        case .customize(_, let name): return name ?? ""

        case .bugs: return LocalString._menu_bugs_title
        case .contacts: return LocalString._menu_contacts_title
        case .settings: return LocalString._menu_settings_title
        case .signout: return LocalString._menu_signout_title
        case .lockapp: return LocalString._menu_lockapp_title
        case .subscription: return LocalString._menu_service_plan_title

        case .addLabel: return LocalString._labels_add_label_action
        case .addFolder: return LocalString._labels_add_folder_action
        case .accountManger: return LocalString._menu_manage_accounts
        case .addAccount: return ""
        }
    }

#if !APP_EXTENSION
    var icon: UIImage? {
        switch self {
        case .provideFeedback:
            return IconProvider.speechBubble
        case .inbox:
            return IconProvider.inbox
        case .draft:
            return IconProvider.file
        case .sent:
            return IconProvider.paperPlane
        case .starred:
            return IconProvider.star
        case .archive:
            return IconProvider.archiveBox
        case .spam:
            return IconProvider.fire
        case .trash:
            return IconProvider.trash
        case .allmail:
            return IconProvider.envelopes
        case .subscription:
            return IconProvider.pencil
        case .settings:
            return IconProvider.cogWheel
        case .contacts:
            return IconProvider.users
        case .bugs:
            return IconProvider.bug
        case .lockapp:
            return IconProvider.lock
        case .signout:
            return IconProvider.arrowOutFromRectangle
        case .customize(_, _):
            return nil
        case .addLabel, .addFolder:
            return IconProvider.plus
        default:
            return nil
        }
    }
#endif

    var toMessageLocation: Message.Location {
        // todo remove Message.Location in future
        switch self {
        case .inbox: return .inbox
        case .draft, .hiddenDraft: return .draft
        case .sent, .hiddenSent: return .sent
        case .starred: return .starred
        case .archive: return .archive
        case .spam: return .spam
        case .trash: return .trash
        case .allmail: return .allmail
        default: return .inbox
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawLabelID == rhs.rawLabelID
    }
}
