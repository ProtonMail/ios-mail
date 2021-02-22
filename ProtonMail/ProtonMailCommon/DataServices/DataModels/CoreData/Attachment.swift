//
//  Attachment.swift
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
    
    //Added in version 1.12.5 to handle the attachment deletion failed issue
    @NSManaged var isSoftDeleted: Bool
}
