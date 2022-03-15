//
//  Contact.swift
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

class Contact: NSManagedObject {
    @NSManaged var userID: String
    @NSManaged var contactID: String
    @NSManaged var name: String
//    @NSManaged var datas: String
    @NSManaged var cardData: String
    @NSManaged var size: NSNumber
    @NSManaged var uuid: String
    @NSManaged var createTime: Date?
    @NSManaged var modifyTIme: Data?

    // local ver 
    @NSManaged var isDownloaded: Bool
    @NSManaged var isCorrected: Bool
    @NSManaged var needsRebuild: Bool
    @NSManaged var isSoftDeleted: Bool

    // relation
    @NSManaged var emails: NSSet

    @objc
    dynamic var sectionName: String {
        let temp = self.name.lowercased()
        if temp.isEmpty || temp.count == 1 {
            return temp
        }
        let index = temp.index(after: temp.startIndex)
        return String(temp.prefix(upTo: index))
    }
}
