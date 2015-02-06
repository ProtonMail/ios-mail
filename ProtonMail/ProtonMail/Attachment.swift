//
//  Attachment.swift
//  ProtonMail
//
//  Created by Eric Chamberlain on 2/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class Attachment: NSManagedObject {
    
    struct Attributes {
        static let entityName = "Attachment"
        
        static let attachmentID = "attachmentID"
    }

    @NSManaged var attachmentID: String
    @NSManaged var data: NSData?
    @NSManaged var fileName: String
    @NSManaged var fileSize: NSNumber
    @NSManaged var mimeType: String
    
    @NSManaged var detail: MessageDetail

    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
}
