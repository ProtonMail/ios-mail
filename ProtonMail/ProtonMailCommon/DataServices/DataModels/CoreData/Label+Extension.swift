//
//  Label+Extension.swift
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


extension Label {
    
    struct Attributes {
        static let entityName = "Label"
        static let labelID = "labelID"
        static let order = "order"
        static let name = "name"
        static let isDisplay = "isDisplay"
        static let color = "color"
        static let type = "type"
        static let exclusive = "exclusive"
        static let userID = "userID"
    }
    
    // MARK: - Public methods
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    open override func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func labelForLableID(_ labelID: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.labelID, matchingValue: labelID) as? Label
    }
    
    class func labelForLabelName(_ name: String,
                                 inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName,
                                                   forKey: Attributes.name,
                                                   matchingValue: name) as? Label
    }
    
    class func labelGroup( by name: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.name : name, Attributes.type : "2"]) as? Label
    }
    
    class func labelGroup( byID: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.labelID : byID, Attributes.type : "2"]) as? Label
    }
}
