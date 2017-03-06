//
//  LabelExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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
    }
    
    // MARK: - Public methods
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func labelForLableID(labelID: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.labelID, matchingValue: labelID) as? Label
    }
}
