//
//  Message.swift
//  ProtonMail
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
import CoreData

class Message: NSManagedObject {

    @NSManaged var bccList: String
    @NSManaged var bccNameList: String
    @NSManaged var body: String
    @NSManaged var ccList: String
    @NSManaged var ccNameList: String
    @NSManaged var expirationTime: NSDate?
    @NSManaged var hasAttachments: Bool
    @NSManaged var header: String
    @NSManaged var isDetailDownloaded: Bool
    @NSManaged var isEncrypted: NSNumber
    @NSManaged var isForwarded: Bool
    @NSManaged var isRead: Bool
    @NSManaged var isReplied: Bool
    @NSManaged var isRepliedAll: Bool
    @NSManaged var isStarred: Bool
    @NSManaged var lastModified: NSDate?
    @NSManaged var locationNumber: NSNumber
    @NSManaged var messageID: String
    @NSManaged var passwordEncryptedBody: String
    @NSManaged var passwordHint: String
    @NSManaged var recipientList: String
    @NSManaged var recipientNameList: String
    @NSManaged var sender: String
    @NSManaged var senderName: String
    @NSManaged var spamScore: NSNumber
    @NSManaged var tag: String
    @NSManaged var time: NSDate?
    @NSManaged var title: String
    @NSManaged var totalSize: NSNumber
    @NSManaged var latestUpdateType : NSNumber
    
    @NSManaged var attachments: NSSet
}
