//
//  MenuItem.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

enum MenuItem: String {//change to Int later.
    case bugs = "Report Bugs"
    case inbox = "Inbox"
    case starred = "Starred"
    case archive = "Archive"
    case drafts = "Drafts"
    case allmail = "All Mail"
    case sent = "Sent"
    case trash = "Trash"
    case spam = "Spam"
    case contacts = "Contacts"
    case settings = "Settings"
    case signout = "Logout"
    case feedback = "Feedback"
    case lockapp = "Lock The App"
    case servicePlan = "Service Plan"
    
    //var identifier: String { return rawValue }
    
    var title: String {
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
            image = "menu_allmail"
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
            image = "menu_allmail-active"
        }
        return image;
    }
    
    
    var menuToLocation : MessageLocation {
        switch self {
        case .inbox:
            return .inbox
        case .starred:
            return .starred
        case .archive:
            return .archive
        case .drafts:
            return .draft
        case .sent:
            return .outbox
        case .trash:
            return .trash
        case .spam:
            return .spam
        case .allmail:
            return .allmail
        default:
            return .inbox
        }
    }
}
