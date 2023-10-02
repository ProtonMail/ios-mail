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

final class EmailPublisher: DataPublisher<Email> {
    init(
        userID: UserID,
        isContactCombine: Bool,
        contextProvider: CoreDataContextProviderProtocol
    ) {
        var predicate: NSPredicate?
        if !isContactCombine {
            predicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, userID.rawValue)
        }
        let sortByTime = NSSortDescriptor(
            key: Email.Attributes.lastUsedTime,
            ascending: false
        )
        let sortByName = NSSortDescriptor(
            key: Email.Attributes.name,
            ascending: true,
            selector: #selector(NSString.caseInsensitiveCompare(_:))
        )
        let sortByEmail = NSSortDescriptor(
            key: Email.Attributes.email,
            ascending: true,
            selector: #selector(NSString.caseInsensitiveCompare(_:))
        )
        super.init(
            entityName: Email.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortByTime, sortByName, sortByEmail],
            contextProvider: contextProvider
        )
    }
}
