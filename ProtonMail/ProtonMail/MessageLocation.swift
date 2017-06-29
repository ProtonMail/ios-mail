//
//  Location.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

public enum MessageLocation: Int, CustomStringConvertible {
    case deleted = -1
    case draft = 1
    case inbox = 0
    case outbox = 2
    case spam = 4
    case archive = 6
    case trash = 3
    case allmail = 5
    case starred = 10
    
    public var actionTitle : String {
        get {
            switch(self) {
            case .deleted:
                return NSLocalizedString("Trash", comment: "Action")
            case .inbox:
                return NSLocalizedString("Move to Inbox", comment: "Action")
            case .draft:
                return NSLocalizedString("Move to Draft", comment: "Action")
            case .outbox:
                return NSLocalizedString("Move to Outbox", comment: "Action")
            case .spam:
                return NSLocalizedString("Move to Spam", comment: "Action")
            case .starred:
                return NSLocalizedString("Add Star", comment: "Action")
            case .archive:
                return NSLocalizedString("Move to Archive", comment: "Action")
            case .trash:
                return NSLocalizedString("Move to Trash", comment: "Action")
            case .allmail:
                return NSLocalizedString("Move to AllMail", comment: "Action") //not in used
            }
        }
    }
    
    public var description : String {
        get {
            switch(self) {
            case .deleted:
                return NSLocalizedString("Deleted", comment: "Title")
            case .inbox:
                return NSLocalizedString("Inbox", comment: "Title")
            case .draft:
                return NSLocalizedString("Draft", comment: "Title")
            case .outbox:
                return NSLocalizedString("Outbox", comment: "Title")
            case .spam:
                return NSLocalizedString("Spam", comment: "Title")
            case .starred:
                return NSLocalizedString("Starred", comment: "Title")
            case .archive:
                return NSLocalizedString("Archive", comment: "Title")
            case .trash:
                return NSLocalizedString("Trash", comment: "Title")
            case .allmail:
                return NSLocalizedString("All Mail", comment: "Title")
            }
        }
    }
    
    public var title : String {
        switch(self) {
        case .inbox:
            return NSLocalizedString("INBOX", comment: "Title")
        case .starred:
            return NSLocalizedString("STARRED", comment: "Title")
        case .draft:
            return NSLocalizedString("DRAFTS", comment: "Title")
        case .outbox:
            return NSLocalizedString("SENT", comment: "Title")
        case .trash:
            return NSLocalizedString("TRASH", comment: "Title")
        case .archive:
            return NSLocalizedString("ARCHIVE", comment: "Title")
        case .spam:
            return NSLocalizedString("SPAM", comment: "Title")
        case .allmail:
            return NSLocalizedString("All Mail", comment: "Title")
        default:
            return NSLocalizedString("INBOX", comment: "Title")
        }
    }
    
    public var key: String {
        switch(self) {
        case .deleted:
            return "Deleted"
        case .inbox:
            return "Inbox"
        case .draft:
            return "Draft"
        case .outbox:
            return "Outbox"
        case .spam:
            return "Spam"
        case .starred:
            return "Starred"
        case .archive:
            return "Archive"
        case .trash:
            return "Trash"
        case .allmail:
            return "AllMail"
        }
    }
    
    var moveAction: MessageAction? {
        switch(self) {
        case .deleted:
            return .delete
        case .inbox:
            return .inbox
        case .spam:
            return .spam
        case .trash:
            return .trash
        case .archive:
            return .archive
        default:
            return nil
        }
    }
}

