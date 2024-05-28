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
import ProtonCoreUIFoundations

enum LabelLocation: Equatable, Hashable, CaseIterable {
    static var allCases: [LabelLocation] = [
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
    case almostAllMail
    case customize(String, String?)
    case scheduled
    case snooze

    case bugs
    case contacts
    case settings
    case signout
    case lockapp
    case subscription
    case referAFriend

    case addLabel
    case addFolder
    case accountManger
    case addAccount

    init(labelID: LabelID, name: String?) {
        self.init(id: labelID.rawValue, name: name)
    }
    
    init(id: String, name: String?) {
        switch id {
        case Message.Location.inbox.rawValue: self = .inbox
        case Message.HiddenLocation.draft.rawValue: self = .hiddenDraft
        case Message.Location.draft.rawValue: self = .draft
        case Message.HiddenLocation.sent.rawValue: self = .hiddenSent
        case Message.Location.sent.rawValue: self = .sent
        case Message.Location.starred.rawValue: self = .starred
        case Message.Location.archive.rawValue: self = .archive
        case Message.Location.spam.rawValue: self = .spam
        case Message.Location.trash.rawValue: self = .trash
        case Message.Location.allmail.rawValue: self = .allmail
        case Message.Location.almostAllMail.rawValue: self = .almostAllMail
        case "Report a problem": self = .bugs
        case "Contacts": self = .contacts
        case "Settings": self = .settings
        case "Logout": self = .signout
        case "Lock The App": self = .lockapp
        case "Subscription": self = .subscription
        case "Add Label": self = .addLabel
        case "Add Folder": self = .addFolder
        case "Account Manager": self = .accountManger
        case "Add Account": self = .addAccount
        case Message.Location.scheduled.rawValue: self = .scheduled
        case "Refer a friend": self = .referAFriend
        case Message.Location.snooze.rawValue: self = .snooze
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
        case .inbox: return Message.Location.inbox.rawValue
        case .hiddenDraft: return Message.HiddenLocation.draft.rawValue
        case .draft: return Message.Location.draft.rawValue
        case .hiddenSent: return Message.HiddenLocation.sent.rawValue
        case .sent: return Message.Location.sent.rawValue
        case .starred: return Message.Location.starred.rawValue
        case .archive: return Message.Location.archive.rawValue
        case .spam: return Message.Location.spam.rawValue
        case .trash: return Message.Location.trash.rawValue
        case .allmail: return Message.Location.allmail.rawValue
        case .almostAllMail: return Message.Location.almostAllMail.rawValue
        case .customize(let id, _): return id

        case .bugs: return "Report a problem"
        case .contacts: return "Contacts"
        case .settings: return "Settings"
        case .signout: return "Logout"
        case .lockapp: return "Lock The App"
        case .subscription: return "Subscription"
        case .referAFriend: return "Refer a friend"

        case .addLabel: return "Add Label"
        case .addFolder: return "Add Folder"
        case .accountManger: return "Account Manager"
        case .addAccount: return "Add Account"
        case .scheduled: return Message.Location.scheduled.rawValue
        case .snooze: return Message.Location.snooze.rawValue
        }
    }

    var labelID: LabelID {
        return LabelID.init(rawValue: rawLabelID)
    }
    
    var localizedTitle: String {
        switch self {
        case .inbox: return LocalString._menu_inbox_title
        case .hiddenDraft: return ""
        case .draft: return LocalString._menu_drafts_title
        case .hiddenSent: return ""
        case .sent: return LocalString._menu_sent_title
        case .starred: return LocalString._menu_starred_title
        case .archive: return LocalString._menu_archive_title
        case .spam: return LocalString._menu_spam_title
        case .trash: return LocalString._menu_trash_title
        case .allmail, .almostAllMail: return LocalString._menu_allmail_title
        case .customize(_, let name): return name ?? ""

        case .bugs: return LocalString._menu_bugs_title
        case .contacts: return LocalString._menu_contacts_title
        case .settings: return LocalString._menu_settings_title
        case .signout: return LocalString._menu_signout_title
        case .lockapp: return LocalString._menu_lockapp_title
        case .subscription: return LocalString._menu_service_plan_title
        case .referAFriend: return LocalString._menu_refer_a_friend

        case .addLabel: return LocalString._labels_add_label_action
        case .addFolder: return LocalString._labels_add_folder_action
        case .accountManger: return LocalString._menu_manage_accounts
        case .addAccount: return ""
        case .scheduled: return LocalString._locations_scheduled_title
        case .snooze: return L10n.Snooze.title
        }
    }

#if !APP_EXTENSION
    var icon: UIImage? {
        switch self {
        case .inbox:
            return IconProvider.inbox
        case .draft:
            return IconProvider.fileEmpty
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
        case .allmail, .almostAllMail:
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
        case .scheduled:
            return IconProvider.clock
        case .referAFriend:
            return IconProvider.heart
        case .snooze:
            return IconProvider.clock
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
