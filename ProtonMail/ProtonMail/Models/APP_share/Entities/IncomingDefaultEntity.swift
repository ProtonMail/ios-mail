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

struct IncomingDefaultEntity: Equatable {
    let email: String
    let id: String?
    let location: Message.Location
    let time: Date
    let userID: UserID
}

extension IncomingDefaultEntity {
    init(_ incomingDefault: IncomingDefault) {
        email = incomingDefault.email
        id = incomingDefault.id

        guard let location = Message.Location(rawValue: incomingDefault.location) else {
            fatalError("Invalid location: \(incomingDefault.location)")
        }
        self.location = location

        time = incomingDefault.time
        userID = .init(rawValue: incomingDefault.userID)
    }
}
