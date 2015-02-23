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
    @NSManaged var fileName: String
    @NSManaged var fileSize: NSNumber
    @NSManaged var localURL: NSURL?
    @NSManaged var mimeType: String
    
    @NSManaged var message: Message

    // MARK: - Private methods
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        if let localURL = localURL {
            var error: NSError? = nil
            if !NSFileManager.defaultManager().removeItemAtURL(localURL, error: &error) {
                NSLog("\(__FUNCTION__) Could not delete \(localURL) with error: \(error)")
            }
        }
    }
}
