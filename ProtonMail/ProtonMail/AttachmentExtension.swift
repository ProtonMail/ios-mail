//
//  AttachmentExtension.swift
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

extension Attachment {

    struct Attributes {
        static let entityName = "Attachment"
        
        static let attachmentID = "attachmentID"
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
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
