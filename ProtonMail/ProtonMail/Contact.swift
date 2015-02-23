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

    // MARK: - Private methods
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set nil string attributes to ""
        for (_, attribute) in entity.attributesByName as [String : NSAttributeDescription] {
            if attribute.attributeType == .StringAttributeType {
                if valueForKey(attribute.name) == nil {
                    setValue("", forKey: attribute.name)
                }
            }
        }
    }
}
