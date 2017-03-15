//
//  Email.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/15/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import CoreData

class Email: NSManagedObject {
    
    @NSManaged var contactID: String
    @NSManaged var emailID: String
    @NSManaged var email: String
    @NSManaged var name: String
    
    @NSManaged var encrypt: NSNumber
    @NSManaged var order: NSNumber
    @NSManaged var type: String
    
    @NSManaged var contact: Contact
}
