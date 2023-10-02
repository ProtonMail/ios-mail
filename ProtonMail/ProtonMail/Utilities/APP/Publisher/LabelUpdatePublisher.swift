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
import Foundation

final class LabelUpdatePublisher: DataPublisher<LabelUpdate> {
    init(userID: UserID, contextProvider: CoreDataContextProviderProtocol) {
        let predicate = NSPredicate(
            format: "(%K == %@)",
            LabelUpdate.Attributes.userID,
            userID.rawValue
        )
        let sortDescriptor = NSSortDescriptor(
            key: LabelUpdate.Attributes.labelID,
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
        super.init(
            entityName: LabelUpdate.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortDescriptor],
            contextProvider: contextProvider
        )
    }
}
