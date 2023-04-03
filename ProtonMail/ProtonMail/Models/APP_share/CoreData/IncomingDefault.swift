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

final class IncomingDefault: NSManagedObject {
    enum Attribute: String {
        static let entityName = "IncomingDefault"

        case id
        @available(*, unavailable, message: "Do not use in NSPredicates. It won't work because email is encrypted.")
        case email
        case isSoftDeleted
        case location
        case time
        case userID
    }

    @NSManaged var email: String
    /// This property is the unique identifier used by the BE.
    /// However, when we create `IncomingDefault`s locally before sending the POST request, we don't have it yet, hence it's optional.
    @NSManaged var id: String?
    @NSManaged var isSoftDeleted: Bool
    /// The raw value of `Message.Location`
    @NSManaged var location: String
    @NSManaged var time: Date
    @NSManaged var userID: String
}
