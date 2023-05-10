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

import CoreData

final class BlockedSendersPublisher: DataPublisher<IncomingDefault> {
    init(contextProvider: CoreDataContextProviderProtocol, userID: UserID) {
        let onlyBlockedPredicate = NSPredicate(
            format: "%K == %@",
            IncomingDefault.Attribute.location.rawValue,
            "\(IncomingDefaultsAPI.Location.blocked.rawValue)"
        )

        let noSoftDeletedPredicate = NSPredicate(
            format: "%K != %@",
            IncomingDefault.Attribute.isSoftDeleted.rawValue,
            NSNumber(true)
        )

        let userIDPredicate = NSPredicate(
            format: "%K == %@",
            IncomingDefault.Attribute.userID.rawValue,
            userID.rawValue
        )

        let subpredicates: [NSPredicate] = [
            onlyBlockedPredicate,
            noSoftDeletedPredicate,
            userIDPredicate
        ]

        super.init(
            entityName: IncomingDefault.Attribute.entityName,
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \IncomingDefault.time, ascending: true)
            ],
            contextProvider: contextProvider
        )
    }
}
