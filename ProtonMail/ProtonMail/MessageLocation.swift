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

enum MessageLocation: Int, Printable {
    case draft = 1
    case inbox = 0
    case outbox = 2
    case spam = 4
    case starred = 5
    case trash = 3
    
    var description : String {
        get {
            switch(self) {
            case inbox:
                return NSLocalizedString("Inbox")
            case draft:
                return NSLocalizedString("Draft")
            case outbox:
                return NSLocalizedString("Outbox")
            case spam:
                return NSLocalizedString("Spam")
            case starred:
                return NSLocalizedString("Starred")
            case trash:
                return NSLocalizedString("Trash")
            }
        }
    }
    
    var key: String {
        switch(self) {
        case inbox:
            return "Inbox"
        case draft:
            return "Draft"
        case outbox:
            return "Outbox"
        case spam:
            return "Spam"
        case starred:
            return "Starred"
        case trash:
            return "Trash"
        }
    }
    
    var moveAction: MessageAction? {
        switch(self) {
        case .inbox:
            return .inbox
        case .spam:
            return .spam
        case .trash:
            return .trash
        default:
            return nil
        }
    }
}
