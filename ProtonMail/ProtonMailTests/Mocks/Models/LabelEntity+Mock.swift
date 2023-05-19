// Copyright (c) 2022 Proton AG
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

@testable import ProtonMail

extension LabelEntity {

    static func makeMock() -> LabelEntity {
        let userID = UserID(String.randomString(100))

        let emails: [EmailEntity] = [1000, 2000].map { order in
            EmailEntity.make(
                contactID: ContactID(String.randomString(100)),
                userID: userID,
                emailID: EmailID(String.randomString(100)),
                email: .randomString(100),
                name: .randomString(100),
                defaults: .random(),
                order: order,
                type: .randomString(100),
                lastUsedTime: Date()
            )
        }

        return LabelEntity.make(
            userID: userID,
            labelID: LabelID(String.randomString(100)),
            parentID: LabelID(String.randomString(100)),
            name: .randomString(100),
            color: .randomString(100),
            type: LabelType.allCases[Int.random(in: 0..<LabelType.allCases.count)],
            sticky: .random(),
            order: 100,
            path: .randomString(100),
            notify: .random(),
            emailRelations: emails,
            isSoftDeleted: .random()
        )
    }

    static func makeMocks(num: Int) -> [LabelEntity] {
        return (0..<num).map { _ in makeMock() }
    }
}
