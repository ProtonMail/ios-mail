//
//  ContextLabel.swift
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

import CoreData
import Foundation

class ContextLabel: NSManagedObject {
    @NSManaged public var messageCount: NSNumber
    @NSManaged public var unreadCount: NSNumber
    @NSManaged public var time: Date
    @NSManaged public var size: NSNumber
    @NSManaged public var attachmentCount: NSNumber
    @NSManaged public var conversations: NSSet
    @NSManaged public var labelID: String
    @NSManaged public var userID: String

    enum Attributes {
        static let entityName = String(describing: ContextLabel.self)
    }

    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
}
