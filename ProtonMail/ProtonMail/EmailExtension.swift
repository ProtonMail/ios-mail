//
//  EmailExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/15/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import CoreData


extension Email {
    struct Attributes {
        static let entityName = "Email"
        static let contactID = "contactID"
        static let emailID = "emailID"
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func EmailForID(_ emailID: String, inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.emailID, matchingValue: emailID) as? Email
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
