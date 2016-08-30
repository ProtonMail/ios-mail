//
//  MessageAction.swift
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

enum MessageAction: String {
    
    // Draft
    case saveDraft = "saveDraft"
    
    // Attachment
    case uploadAtt = "uploadAtt"
    case deleteAtt = "deleteAtt"
    
    // Read/unread
    case read = "read"
    case unread = "unread"
    
    // Star/unstar
    case star = "star"
    case unstar = "unstar"
    
    // Move mailbox
    case delete = "delete"
    case inbox = "inbox"
    case spam = "spam"
    case trash = "trash"
    case archive = "archive"
    
    // Send
    case send = "send"
    
    // Empty
    case emptyTrash = "emptyTrash"
    case emptySpam = "emptySpam"
}


enum MessageLastUpdateType: String {
    
    // Draft
    case saveDraft = "saveDraft"
    
    // Read/unread
    case read = "read"
    case unread = "unread"
    
    // Star/unstar
    case star = "star"
    case unstar = "unstar"
    
    // Move mailbox
    case delete = "delete"
    case inbox = "inbox"
    case spam = "spam"
    case trash = "trash"
    case archive = "archive"
    
    // Send
    case send = "send"
}

public enum MessageSwipeAction : Int, CustomStringConvertible {
    case trash = 0
    case spam = 1
    case star = 2
    case archive = 3
    
    public var description : String {
        get {
            switch(self) {
            case trash:
                return NSLocalizedString("Trash")
            case spam:
                return NSLocalizedString("Spam")
            case star:
                return NSLocalizedString("Star")
            case archive:
                return NSLocalizedString("Archive")
            }
        }
    }
    
    var actionColor: UIColor {
        switch(self) {
        case .trash:
            return UIColor.redColor()
        default:
            return UIColor.ProtonMail.MessageActionTintColor
        }
    }
}

