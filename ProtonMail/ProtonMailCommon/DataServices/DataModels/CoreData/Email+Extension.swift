//
//  Email+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import CoreData


extension Email {
    struct Attributes {
        static let entityName = "Email"
        static let contactID = "contactID"
        static let email = "email"
        static let emailID = "emailID"
        static let userID = "userID"
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func EmailForID(_ emailID: String, inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.emailID, matchingValue: emailID) as? Email
    }
    
    class func EmailForAddress(_ address: String, inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.email, matchingValue: address) as? Email
    }
    
    class func EmailForAddressWithContact(_ address: String,
                                          contactID: String,
                                          inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        if let tempResults = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                  forKey: Attributes.email,
                                                                  matchingValue: address) as? [Email] {
            for result in tempResults {
                if result.contactID == contactID {
                    return result
                }
            }
        }
        return nil
    }

//    class func findEmails(_ emails: [String], inManagedObjectContext context: NSManagedObjectContext) -> [Email]? {
//        var out : [Email]?
//        context.performAndWait {
//            out = context.objectsWithEntityName(Attributes.entityName, forKey: Attributes.email, forManagedObjectIDs: emails) as? [Email]
//        }
//        return out
//    }
    
    class func findEmailsController(_ emails: [String], inManagedObjectContext context: NSManagedObjectContext) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let controller = context.fetchedControllerEntityName(entityName: Attributes.entityName, forKey: Attributes.email, forManagedObjectIDs: emails)
        do {
            try controller?.performFetch()
        } catch _ {
            return nil
        }
        return controller
    }

    func log() {
        PMLog.D("EmailID: \(self.emailID)")
        PMLog.D("ContactID: \(self.contactID)")
        PMLog.D("Email: \(self.email)")
        PMLog.D("Name: \(self.name)")
        //PMLog.D("Encrypt: \(self.encrypt)")
        PMLog.D("Order: \(self.order)")
        PMLog.D("Type: \(self.type)")
    }
    
    func emailType() -> String {
//        let pasred = type.parseJson();
        return type;
    }
}


//Extension::Array - Email
extension Array where Element: Email {
    func order() -> [Email] {
        return self.sorted { $0.order.compare($1.order) == .orderedAscending }
    }
}
