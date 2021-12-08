//
//  MessageDataServiceHelper.swift
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

import CoreData
import Foundation

final class MessageDataServiceHelper {
    /// Merge the existed message with event API response if needed
    /// - Parameter response: Message event
    /// - Returns: Should skip the following flow?
    static func mergeDraftIfNeeded(event: MessageEvent,
                                   context: NSManagedObjectContext) -> Bool {
        guard let jsonDict = event.message,
              event.isDraft,
              let existMes = Message.messageForMessageID(event.ID ,
                                                         inManagedObjectContext: context),
              existMes.hasMetaData else { return false }
        
        if let subject = jsonDict["Subject"] as? String {
            existMes.title = subject
        }
        if let toList = jsonDict["ToList"] as? [[String: Any]] {
            existMes.toList = toList.json()
        }
        if let bccList = jsonDict["BCCList"] as? [[String: Any]] {
            existMes.bccList = bccList.json()
        }
        if let ccList = jsonDict["CCList"] as? [[String: Any]] {
            existMes.ccList = ccList.json()
        }
        if let date = event.parsedTime {
            existMes.time = date
        }
        _ = context.saveUpstreamIfNeeded()
        return true
    }
}
