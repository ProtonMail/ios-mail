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

final public class Message: NSManagedObject {

    @NSManaged public var bccList: String
    @NSManaged public var bccNameList: String
    @NSManaged public var body: String
    @NSManaged public var ccList: String
    @NSManaged public var ccNameList: String
    @NSManaged public var expirationTime: Date?
    @NSManaged public var hasAttachments: Bool   //removed
    @NSManaged public var numAttachments: NSNumber
    @NSManaged public var header: String?
    @NSManaged public var isDetailDownloaded: Bool
    @NSManaged public var isEncrypted: NSNumber
    @NSManaged public var isForwarded: Bool
    @NSManaged public var isRead: Bool
    @NSManaged public var isReplied: Bool
    @NSManaged public var isRepliedAll: Bool
    @NSManaged public var isStarred: Bool    //Deprecated, use LabelIDs instead
    @NSManaged public var lastModified: Date?
    @NSManaged public var locationNumber: NSNumber  //Deprecated, use LabelIDs instead
    @NSManaged public var messageID: String
    @NSManaged public var passwordEncryptedBody: String
    @NSManaged public var password: String
    @NSManaged public var passwordHint: String
    @NSManaged public var replyTo: String?   //Deprecated, use replyTos instead
    @NSManaged public var replyTos: String?
    @NSManaged public var senderObject: String?
    @NSManaged public var recipientList: String
    @NSManaged public var recipientNameList: String
    @NSManaged public var senderAddress: String
    @NSManaged public var senderName: String
    @NSManaged public var spamScore: NSNumber
    @NSManaged public var tag: String
    @NSManaged public var time: Date?
    @NSManaged public var title: String
    @NSManaged public var totalSize: NSNumber
    @NSManaged public var latestUpdateType : NSNumber
    @NSManaged public var needsUpdate : Bool
    @NSManaged public var orginalMessageID: String?
    @NSManaged public var orginalTime: Date?
    @NSManaged public var action: NSNumber?
    @NSManaged public var isSoftDelete: Bool
    @NSManaged public var expirationOffset : Int32
    
    @NSManaged public var addressID : String?
    
    @NSManaged public var messageType : NSNumber  // 0 message 1 rate
    @NSManaged public var messageStatus : NSNumber  // bit 0x00000000 no metadata  0x00000001 has
    @NSManaged public var mimeType : String?
    
    @NSManaged public var isShowedImages : Bool
    
    @NSManaged public var attachments: NSSet
    @NSManaged public var labels: NSSet
}

