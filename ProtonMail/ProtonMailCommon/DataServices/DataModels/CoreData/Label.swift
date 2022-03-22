//
//  Label.swift
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

class Label: NSManagedObject {
    @NSManaged var userID: String

    @NSManaged var labelID: String
    @NSManaged var name: String
    @NSManaged var parentID: String
    @NSManaged var path: String
    /// label color
    @NSManaged var color: String

    /// 0 = show the label in the sidebar, 1 = hide label from sidebar.
    @available(*, deprecated, message: "Deprecated in v4")
    @NSManaged var isDisplay: Bool

    /// (v3 api)1 => Message Labels (default), 2 => Contact Groups
    /// (v4 api)1 => Message Labels, 2 => Contact Groups, 3 => Message Folders
    @NSManaged var type: NSNumber

    /// 0 => inclusive (label), 1 => exclusive (folder), message type only
    @available(*, deprecated, message: "Deprecated in v4")
    @NSManaged var exclusive: Bool

    /// 0 => not sticky, 1 => stick to the page in the sidebar
    @NSManaged var sticky: NSNumber
    /// 0 => no desktop/email notifications, 1 => notifications, folders only, default is 1 for folders
    @NSManaged var notify: NSNumber

    /// start at 1 , lower number on the top
    @NSManaged var order: NSNumber

    @NSManaged var messages: NSSet
    @NSManaged var emails: NSSet
    @NSManaged var isSoftDeleted: Bool
}

// lableID 
//    case draft = 1
//    case inbox = 0
//    case outbox = 2
//    case spam = 4
//    case archive = 6
//    case trash = 3
//    case allmail = 5
//    case starred = 10
