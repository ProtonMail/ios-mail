// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_Keymaker

class ConversationMigrationPolicy: NSEntityMigrationPolicy {

    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        guard sInstance.entity.name == Conversation.Attributes.entityName,
              keymaker.mainKeyExists() else {
            return
        }

        // Setup new version of Conversation
        let newConversation = NSEntityDescription.insertNewObject(
            forEntityName: Conversation.Attributes.entityName,
            into: manager.destinationContext
        )

        for key in Conversation.Attributes.allCases {
            let value = sInstance.primitiveValue(forKey: key.rawValue)
            newConversation.setValue(value, forKey: key.rawValue)
        }

        manager.associate(sourceInstance: sInstance, withDestinationInstance: newConversation, for: mapping)
    }
}
