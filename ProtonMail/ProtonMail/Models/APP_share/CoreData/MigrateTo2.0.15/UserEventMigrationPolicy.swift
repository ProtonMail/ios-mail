// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData

class UserEventMigrationPolicy: NSEntityMigrationPolicy {

    // Remove duplicated data of the UserEvent since we added unique constraint on the `userID` field in the DB.
    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        let sourceContext = manager.sourceContext

        let request = NSFetchRequest<NSManagedObject>(entityName: UserEvent.Attributes.entityName)
        let events = try sourceContext.fetch(request)

        let userIDs = Set(
            events.compactMap { $0.value(forKeyPath: UserEvent.Attributes.userID) as? String }
                .filter { !$0.isEmpty }
        )
        var itemsToKeep: [NSManagedObject] = []
        for userID in userIDs {
            // keep one item with valid data and delete the rest.
            if let itemToKeep = events.first(where: { event in
                event.value(forKeyPath: UserEvent.Attributes.userID) as? String == userID &&
                event.value(forKey: UserEvent.Attributes.eventID) as? String != nil &&
                event.value(forKey: UserEvent.Attributes.updateTime) as? Date != nil
            }) {
                itemsToKeep.append(itemToKeep)
            }
        }
        for event in events where !itemsToKeep.contains(event) {
            sourceContext.delete(event)
        }
    }
}
