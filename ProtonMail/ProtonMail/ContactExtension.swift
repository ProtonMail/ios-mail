//
//  ContactExtension.swift
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

import Foundation
import CoreData

extension Contact {

    struct Attributes {
        static let entityName = "Contact"
        static let contactID = "contactID"
        static let email = "email"
        static let name = "name"
    }

    // MARK: - Public methods
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func contactForContactID(contactID: String, inManagedObjectContext context: NSManagedObjectContext) -> Contact? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.contactID, matchingValue: contactID) as? Contact
    }
}
