//
//  Attachment.swift
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

class Attachment: NSManagedObject {
    
    @NSManaged var attachmentID: String
    @NSManaged var fileData: NSData?
    @NSManaged var keyPacket: NSData?
    @NSManaged var fileName: String
    @NSManaged var fileSize: NSNumber
    @NSManaged var localURL: NSURL?
    @NSManaged var mimeType: String
    
    @NSManaged var message: Message
}
