// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import CoreData

extension EventsService {

    final class Helper {
        static func mergeDraft(event: MessageEvent,
                               existing: Message) {
            guard let response = event.message else { return }
            if let subject = response["Subject"] as? String {
                existing.title = subject
            }
            if let toList = response["ToList"] as? [[String: Any]] {
                existing.toList = toList.json()
            }
            if let bccList = response["BCCList"] as? [[String: Any]] {
                existing.bccList = bccList.json()
            }
            if let ccList = response["CCList"] as? [[String: Any]] {
                existing.ccList = ccList.json()
            }
            if let time = event.parsedTime {
                existing.time = time
            }
            if let conversationID = response["ConversationID"] as? String {
                existing.conversationID = conversationID
            }
            if let labelIDs = response["LabelIDs"] as? [String] {
                // For undo send action, the label of the message will change
                let currentLabels = existing.getLabelIDs()
                currentLabels.forEach { existing.remove(labelID: $0) }
                labelIDs.forEach { existing.add(labelID: $0) }
            }
        }

        static func getMessageWithMetaData(for draftID: String,
                                           context: NSManagedObjectContext) -> Message? {
            guard let existing = Message.messageForMessageID(draftID,
                                                             inManagedObjectContext: context),
                  existing.hasMetaData else { return nil }
            return existing
        }
    }
}
