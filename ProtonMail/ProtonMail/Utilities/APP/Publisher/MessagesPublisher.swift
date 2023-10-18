// Copyright (c) 2023 Proton Technologies AG
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

import Foundation

final class MessagesPublisher: DataPublisher<Message> {
    init(messageIDs: [MessageID], contextProvider: CoreDataContextProviderProtocol) {
        let predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, messageIDs.map { $0.rawValue })
        let sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Message.time), ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
        ]
        super.init(
            entityName: Message.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            contextProvider: contextProvider
        )
    }
}
