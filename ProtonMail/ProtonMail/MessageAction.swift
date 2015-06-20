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
    
    // Send
    case send = "send"
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
    
    // Send
    case send = "send"
}


