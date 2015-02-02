//
//  Message.swift
//  ProtonMail
//
//  Created by Eric Chamberlain on 1/30/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class Message: NSManagedObject {

    @NSManaged var messageID: String
    @NSManaged var time: NSDate
    @NSManaged var title: String
    @NSManaged var senderName: String
    @NSManaged var sender: String
    @NSManaged var recipientNameList: String
    @NSManaged var recipientList: String
    @NSManaged var totalSize: Int32
    @NSManaged var isAttachment: Bool
    @NSManaged var isRead: Bool
    @NSManaged var isEncrypted: Bool
    @NSManaged var tag: String
    @NSManaged var expirationTime: NSDate?
    @NSManaged var isReplied: Bool
    @NSManaged var isRepliedAll: Bool
    @NSManaged var isForwarded: Bool

}
