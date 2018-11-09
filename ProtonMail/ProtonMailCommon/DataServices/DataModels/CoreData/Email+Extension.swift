//
//  Email+Extension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import CoreData


extension Email {
    struct Attributes {
        static let entityName = "Email"
        static let contactID = "contactID"
        static let email = "email"
        static let emailID = "emailID"
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
