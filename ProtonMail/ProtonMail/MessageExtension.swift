//
//  MessageExtension.swift
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

import CoreData
import Foundation

extension Message {
    
    struct Attributes {
        static let entityName = "Message"
        static let locationNumber = "locationNumber"
        static let isDetailDownloaded = "isDetailDownloaded"
        static let isRead = "isRead"
        static let isStarred = "isStarred"
        static let messageID = "messageID"
        static let time = "time"
    }
    
    typealias CompletionBlock = MessageDataService.CompletionBlock
    
    struct Constants {
        static let starredTag = "starred"
    }
    
    // MARK: - Public methods
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    class func messagesForObjectIDs(objectIDs: [NSManagedObjectID], inManagedObjectContext context: NSManagedObjectContext, error: NSErrorPointer) -> [Message]? {
        return context.managedObjectsWithEntityName(Attributes.entityName, forManagedObjectIDs: objectIDs, error: error) as? [Message]
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    func fetchDetailIfNeeded(completion: CompletionBlock) {
        sharedMessageDataService.fetchMessageDetailForMessage(self, completion: completion)
    }
    
    func updateTag(tag: String) {
        self.tag = tag
        isStarred = tag.rangeOfString(Constants.starredTag) != nil
    }
}