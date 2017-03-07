//
//  Contact.swift
//  ProtonMail
//
//  Created by Eric Chamberlain on 2/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

public class Contact: NSManagedObject {

    @NSManaged var contactID: String
    @NSManaged var name: String
//    @NSManaged var datas: String
    @NSManaged var cardData: String
    @NSManaged var size : NSNumber
    @NSManaged var uuid: String
    @NSManaged var createTime : Date?
    @NSManaged var modifyTIme : Data?
    
    //local ver 
    @NSManaged var isDownloaded: Bool

    // relation
    @NSManaged var emails: NSSet
}
