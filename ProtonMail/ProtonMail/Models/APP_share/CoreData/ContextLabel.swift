//
//  ContextLabel.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
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

import CoreData
import Foundation

class ContextLabel: NSManagedObject {
    @NSManaged var messageCount: NSNumber
    @NSManaged var unreadCount: NSNumber
    @NSManaged var time: Date?
    @NSManaged var size: NSNumber
    @NSManaged var attachmentCount: NSNumber
    @NSManaged var conversation: Conversation
    @NSManaged var conversationID: String
    @NSManaged var labelID: String
    @NSManaged var userID: String
    @NSManaged var order: NSNumber
    @NSManaged var isSoftDeleted: Bool

    enum Attributes {
        static let entityName = String(describing: ContextLabel.self)
        static let userID = "userID"
        static let labelID = "labelID"
        static let unreadCount = "unreadCount"
        static let isSoftDeleted = "isSoftDeleted"
    }

    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
}
