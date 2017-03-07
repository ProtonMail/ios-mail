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
                return NSLocalizedString("Trash")
            case .inbox:
                return NSLocalizedString("Move to Inbox")
            case .draft:
                return NSLocalizedString("Move to Draft")
            case .outbox:
                return NSLocalizedString("Move to Outbox")
            case .spam:
                return NSLocalizedString("Move to Spam")
            case .starred:
                return NSLocalizedString("Add Star")
            case .archive:
                return NSLocalizedString("Move to Archive")
            case .trash:
                return NSLocalizedString("Move to Trash")
            case .allmail:
                return NSLocalizedString("Move to AllMail") //not in used
            }
        }
    }
    
    
    public var description : String {
        get {
            switch(self) {
            case .deleted:
                return NSLocalizedString("Deleted")
            case .inbox:
                return NSLocalizedString("Inbox")
            case .draft:
                return NSLocalizedString("Draft")
            case .outbox:
                return NSLocalizedString("Outbox")
            case .spam:
                return NSLocalizedString("Spam")
            case .starred:
                return NSLocalizedString("Starred")
            case .archive:
                return NSLocalizedString("Archive")
            case .trash:
                return NSLocalizedString("Trash")
            case .allmail:
                return NSLocalizedString("All Mail")
            }
        }
    }
    
    public var title : String {
        
        switch(self) {
        case .inbox:
            return "INBOX"
        case .starred:
            return "STARRED"
        case .draft:
            return "DRAFTS"
        case .outbox:
            return "SENT"
        case .trash:
            return "TRASH"
        case .archive:
            return "ARCHIVE"
        case .spam:
            return "SPAM"
        case .allmail:
            return NSLocalizedString("All Mail")
        default:
            return "INBOX"
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
            return NSLocalizedString("AllMail")
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

