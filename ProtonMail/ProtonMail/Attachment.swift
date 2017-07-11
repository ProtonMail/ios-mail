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

public class Attachment: NSManagedObject {
    
    @NSManaged public var attachmentID: String
    @NSManaged public var fileData: Data?
    @NSManaged public var keyPacket: String?
    @NSManaged public var fileName: String
    @NSManaged public var fileSize: NSNumber
    @NSManaged public var localURL: URL?
    @NSManaged public var mimeType: String
    @NSManaged public var isTemp: Bool
    
    @NSManaged public var headerInfo: String?
    
    @NSManaged public var message: Message
}
