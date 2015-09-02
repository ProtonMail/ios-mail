//
//  MenuItem.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit




enum MenuItem: String {
    case bugs = "Report Bugs"
    case inbox = "Inbox"
    case starred = "Starred"
    case archive = "Archive"
    case drafts = "Drafts"
    case sent = "Sent"
    case trash = "Trash"
    case spam = "Spam"
    case contacts = "Contacts"
    case settings = "Settings"
    case signout = "Logout"
    
    var identifier: String { return rawValue }
    
    var hasCount : Bool {
        var has = false
        switch self {
        case inbox, archive, starred, drafts, sent, trash, spam:
            has = true
            break
        default:
            has = false
        }
        return has;
    }
    
    var image : String {
        var image = "menu_inbox"
        switch self {
        case bugs:
            image = "menu_bugs"
            break
        case inbox:
            image = "menu_inbox"
            break
        case archive:
            image = "menu_archive"
            break
        case starred:
            image = "menu_starred"
            break
        case drafts:
            image = "menu_draft"
            break
        case sent:
            image = "menu_sent"
            break
        case trash:
            image = "menu_trash"
            break
        case spam:
            image = "menu_spam"
            break
        case contacts:
            image = "menu_contacts"
            break
        case settings:
            image = "menu_settings"
            break
        case signout:
            image = "menu_logout"
            break
        default:
            break
        }
        return image;
    }
    
    var imageSelected : String {
        var image = "menu_inbox-active"
        switch self {
        case bugs:
            image = "menu_bugs-active"
            break
        case inbox:
            image = "menu_inbox-active"
            break
        case archive:
            image = "menu_archive-active"
            break
        case starred:
            image = "menu_starred-active"
            break
        case drafts:
            image = "menu_draft-active"
            break
        case sent:
            image = "menu_sent-active"
            break
        case trash:
            image = "menu_trash-active"
            break
        case spam:
            image = "menu_spam-active"
            break
        case contacts:
            image = "menu_contacts-active"
            break
        case settings:
            image = "menu_settings-active"
            break
        case signout:
            image = "menu_logout-active"
            break
        default:
            break
        }
        return image;
    }

    
    var menuToLocation : MessageLocation {
        switch self {
        case inbox:
            return .inbox
        case starred:
            return .starred
        case archive:
            return .archive
        case drafts:
            return .draft
        case sent:
            return .outbox
        case trash:
            return .trash
        case spam:
            return .spam
        default:
            return .inbox
        }
    }
    
    var selectedImage : String {
        var image = "inbox_selected"
        switch self {
        case bugs:
            image = "bug_selected"
            break
        case inbox, archive:
            image = "inbox_selected"
            break
        case starred:
            image = "starred_selected"
            break
        case drafts:
            image = "draft_selected"
            break
        case sent:
            image = "sent_selected"
            break
        case trash:
            image = "trash_selected"
            break
        case spam:
            image = "spam_selected"
            break
        case contacts:
            image = "contact_selected"
            break
        case settings:
            image = "settings_selected"
            break
        case signout:
            image = "signout_selected"
            break
        default:
            image = "inbox_selected"
            break
        }
        return image;
    }
    
}
