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
    
    @NSManaged var attachmentID: String
    @NSManaged var data: NSData?
    @NSManaged var fileName: String
    @NSManaged var fileSize: NSNumber
    @NSManaged var mimeType: String
    
    @NSManaged var detail: MessageDetail

}
