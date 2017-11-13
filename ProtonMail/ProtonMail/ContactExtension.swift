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
        static let name = "name"
        static let emails = "emails"
    }

    // MARK: - methods
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func contactForContactID(_ contactID: String, inManagedObjectContext context: NSManagedObjectContext) -> Contact? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.contactID, matchingValue: contactID) as? Contact
    }
    //notes: if this function call `getEmails` app crashes because it seems override the accessor CoreData creates?
    //http://stackoverflow.com/questions/36878192/inverse-relationship-with-core-data-causes-crash-when-adding-object-to-nsset
    func getEmailsArray() -> [Email]? {
        let emails = self.emails.allObjects as? [Email]
        return emails?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.order.compare(rhs.order) == .orderedAscending
        })
    }
    
    func getDisplayEmails() -> String {
        if let emails = getEmailsArray()?.order() {
            let arrayMap: Array = emails.map(){ $0.email }
            return arrayMap.joined(separator: ",")
        }
        return ""
    }
    
    func getEmail(at i: Int) -> Email? {
        if let emailArray = getEmailsArray(), i < emails.count {
            return emailArray[i]
        }
        return nil
    }
    
    
    func log() {
        PMLog.D("ContactID: \(self.contactID)")
        print("Name: \(self.name)")
        print("Cards: \(self.cardData)")
        print("Size: \(self.size)")
        print("UUID: \(self.uuid)")
        print("CreateTime: \(String(describing: self.createTime))")
        print("ModifyTime: \(String(describing: self.modifyTIme))")
    }
    
    func getCardData() -> [CardData] {
        var cards : [CardData] = [CardData]()
        do {
            if let data = self.cardData.data(using: String.Encoding.utf8) {
                let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [Any]
                if let vcards = decoded as? [[String : Any]] {
                    for c in vcards {
                        let t = c["Type"] as? Int ?? 0
//                        let t = Int(c["Type"] as? String ?? "0") ?? 0
                        let d = c["Data"] as? String ?? ""
                        let s = c["Signature"] as? String ?? ""
                        cards.append(CardData(t: CardDataType(rawValue: t)!, d: d, s: s))
                    }
                }
            }
        } catch let ex as NSError {
            PMLog.D(" func parseJson() -> error error \(ex)")
        }
        return cards
    }
}

