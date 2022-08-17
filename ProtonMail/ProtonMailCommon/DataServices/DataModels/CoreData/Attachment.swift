//
//  Attachment.swift
//  Proton Mail
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

import CoreData
import Foundation

class Attachment: NSManagedObject {
    @NSManaged var attachmentID: String
    @NSManaged var fileData: Data?
    @NSManaged var keyPacket: String?
    @NSManaged var fileName: String
    @NSManaged var fileSize: NSNumber
    @NSManaged var localURL: URL?
    @NSManaged var mimeType: String
    @NSManaged var isTemp: Bool
    @NSManaged var keyChanged: Bool
    @NSManaged var userID: String

    @NSManaged var headerInfo: String?

    @NSManaged var message: Message

    // Added in version 1.12.5 to handle the attachment deletion failed issue
    @NSManaged var isSoftDeleted: Bool
    // Used to save the ordering info locally.
    @NSManaged var order: Int32
}
