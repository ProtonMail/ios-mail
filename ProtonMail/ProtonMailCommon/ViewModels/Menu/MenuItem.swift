//
//  MenuItem.swift
//  ProtonMail - Created on 8/10/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

enum MenuItem: String {//change to Int later.
    case bugs    = "Report Bugs"
    case inbox   = "Inbox"
    case starred = "Starred"
    case archive = "Archive"
    case drafts  = "Drafts"
    case allmail = "All Mail"
    case sent    = "Sent"
    case trash   = "Trash"
    case spam    = "Spam"
    case contacts    = "Contacts"
    case settings    = "Settings"
    case signout     = "Logout"
    case feedback    = "Feedback"
    case lockapp     = "Lock The App"
    case servicePlan = "Service Plan"

    var localizedTitle: String {
        switch self {
        case .bugs:
            return LocalString._menu_bugs_title
        case .inbox:
            return LocalString._menu_inbox_title
        case .starred:
            return LocalString._menu_starred_title
        case .archive:
            return LocalString._menu_archive_title
        case .drafts:
            return LocalString._menu_drafts_title
        case .allmail:
            return LocalString._menu_allmail_title
        case .sent:
            return LocalString._menu_sent_title
        case .trash:
            return LocalString._menu_trash_title
        case .spam:
            return LocalString._menu_spam_title
        case .contacts:
            return LocalString._menu_contacts_title
        case .settings:
            return LocalString._menu_settings_title
        case .signout:
            return LocalString._menu_signout_title
        case .feedback:
            return LocalString._menu_feedback_title
        case .lockapp:
            return LocalString._menu_lockapp_title
        case .servicePlan:
            return LocalString._menu_service_plan_title
        }
    }
    
    var hasCount : Bool {
        var has = false
        switch self {
        case .inbox, .archive, .starred, .drafts, .sent, .trash, .spam:
            has = true
        default:
            has = false
        }
        return has;
    }
    
    var image : String {
        var image = "menu_inbox"
        switch self {
        case .bugs:
            image = "menu_bugs"
        case .inbox:
            image = "menu_inbox"
        case .archive:
            image = "menu_archive"
        case .starred:
            image = "menu_starred"
        case .drafts:
            image = "menu_draft"
        case .sent:
            image = "menu_sent"
        case .trash:
            image = "menu_trash"
        case .spam:
            image = "menu_spam"
        case .contacts:
            image = "menu_contacts"
        case .settings:
            image = "menu_settings"
        case .signout:
            image = "menu_logout"
        case .feedback:
            image = "menu_feedback"
        case .lockapp:
            image = "menu_lockapp"
        case .allmail:
            image = "menu_allmail"
        case .servicePlan:
            image = "menu_serviceplan"
        }
        return image;
    }
    
    var imageSelected : String {
        var image = "menu_inbox-active"
        switch self {
        case .bugs:
            image = "menu_bugs-active"
        case .inbox:
            image = "menu_inbox-active"
        case .archive:
            image = "menu_archive-active"
        case .starred:
            image = "menu_starred-active"
        case .drafts:
            image = "menu_draft-active"
        case .sent:
            image = "menu_sent-active"
        case .trash:
            image = "menu_trash-active"
        case .spam:
            image = "menu_spam-active"
        case .contacts:
            image = "menu_contacts-active"
        case .settings:
            image = "menu_settings-active"
        case .signout:
            image = "menu_logout-active"
        case .feedback:
            image = "menu_feedback-active"
        case .lockapp:
            image = "menu_lockapp"
        case .allmail:
            image = "menu_allmail-active"
        case .servicePlan:
            image = "menu_serviceplan-active"
        }
        return image;
    }
    
    
    var menuToLabel : Message.Location {
        switch self {
        case .inbox:
            return Message.Location.inbox
        case .starred:
            return Message.Location.starred
        case .archive:
            return Message.Location.archive
        case .drafts:
            return Message.Location.draft
        case .sent:
            return Message.Location.sent
        case .trash:
            return Message.Location.trash
        case .spam:
            return Message.Location.spam
        case .allmail:
            return Message.Location.allmail
        default:
            return Message.Location.inbox
        }
    }
}
