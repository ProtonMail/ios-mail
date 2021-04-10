//
//  ContextLabelUpdate+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import CoreData
import Foundation

extension ContextLabelUpdate {
    enum Attributes {
        static let entityName = "ContextLabelUpdate"
        static let userID = "userID"
        static let labelID = "labelID"
    }

    class func lastContextUpdate(by labelID: String, userID: String, inManagedObjectContext context: NSManagedObjectContext) -> ContextLabelUpdate? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.labelID: labelID, Attributes.userID: userID]) as? ContextLabelUpdate
    }

    class func newContextLabelUpdate(by labelID: String, userID: String, inManagedObjectContext context: NSManagedObjectContext) -> ContextLabelUpdate {
        let update = ContextLabelUpdate(context: context)

        update.start = Date.distantPast
        update.end = Date.distantPast
        update.update = Date.distantPast

        update.labelID = labelID
        update.userID = userID

        update.total = 0
        update.unread = 0

        if let error = context.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }

        return update
    }

    class func remove(by userID: String, inManagedObjectContext context: NSManagedObjectContext) -> Bool {
        if let toDeletes = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                matching: [Attributes.userID: userID]) as? [ContextLabelUpdate]
        {
            for update in toDeletes {
                context.delete(update)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                return true
            }
        }
        return false
    }

    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
}
