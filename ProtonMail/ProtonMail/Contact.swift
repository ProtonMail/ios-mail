//
//  Contact.swift
//  ProtonMail
//
//  Created by Eric Chamberlain on 2/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class Contact: NSManagedObject {

    @NSManaged var contactID: String
    @NSManaged var name: String
    @NSManaged var email: String
}
