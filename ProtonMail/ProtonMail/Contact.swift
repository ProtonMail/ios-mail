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

    @NSManaged public var contactID: String
    @NSManaged public var name: String
    @NSManaged public var email: String
}
