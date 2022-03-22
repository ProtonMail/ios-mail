//
//  Label+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

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
        static let emails = "emails"
        static let isSoftDeleted = "isSoftDeleted"
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

    class func labelFetchController(for labelID: String, inManagedObjectContext context: NSManagedObjectContext) -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K == 0", Attributes.labelID, labelID, Attributes.isSoftDeleted)
        let strComp = NSSortDescriptor(key: Label.Attributes.name,
                                       ascending: true,
                                       selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        let fetchedController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedController
    }

    class func labelForLabelID(_ labelID: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.labelID, matchingValue: labelID) as? Label
    }

    class func labelForLabelName(_ name: String,
                                 inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName,
                                                   forKey: Attributes.name,
                                                   matchingValue: name) as? Label
    }

    class func labelGroup( byID: String, inManagedObjectContext context: NSManagedObjectContext) -> Label? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.labelID: byID, Attributes.type: NSNumber(value: 2)]) as? Label
    }

    class func makeGroupLabel(context: NSManagedObjectContext, userID: String, color: String, name: String, emailIDs: [String]) -> Label {
        let label = Label(context: context)
        label.userID = userID
        label.labelID = UUID().uuidString
        label.name = name
        label.path = name
        label.color = color
        label.type = NSNumber(value: 2)
        label.sticky = NSNumber(value: 0)
        label.notify = NSNumber(value: 0)
        label.order = NSNumber(value: 20)

        let mails = emailIDs
            .compactMap { Email.EmailForID($0, inManagedObjectContext: context) }
        label.emails = Set(mails) as NSSet
        return label
    }
}
