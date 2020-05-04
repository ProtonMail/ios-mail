//
//  Contact+Extension.swift
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

extension Contact {

    struct Attributes {
        static let entityName = "Contact"
        static let contactID = "contactID"
        static let name = "name"
        static let emails = "emails"
        static let userID = "userID"
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
    
    func fixName(force: Bool = false) -> Bool {
        if !self.isCorrected || force {
            let name = self.name
            if !name.isEmpty {
                self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                if let emails = self.getEmailsArray(), let email = emails.first {
                    self.name = email.email.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            self.isCorrected = true
            return true
        }
        return false
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
        PMLog.D("Name: \(self.name)")
        PMLog.D("Cards: \(self.cardData)")
        PMLog.D("Size: \(self.size)")
        PMLog.D("UUID: \(self.uuid)")
        PMLog.D("CreateTime: \(String(describing: self.createTime))")
        PMLog.D("ModifyTime: \(String(describing: self.modifyTIme))")
    }
    
    func getCardData() -> [CardData] {
        var cards : [CardData] = [CardData]()
        do {
            if let data = self.cardData.data(using: String.Encoding.utf8) {
                let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [Any]
                if let vcards = decoded as? [[String : Any]] {
                    for c in vcards {
                        let t = c["Type"] as? Int ?? 0
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

