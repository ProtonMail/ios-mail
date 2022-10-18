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
        let contextProviderMock = MockCoreDataContextProvider()

        return contextProviderMock.enqueue { context in
            let label = Label(context: context)
            label.userID = String.randomString(100)
            label.labelID = String.randomString(100)
            label.name = String.randomString(100)
            label.parentID = String.randomString(100)
            label.path = String.randomString(100)
            label.color = String.randomString(100)
            label.type = NSNumber(value: Int.random(in: 1...3))
            label.sticky = NSNumber(value: Bool.random())
            label.notify = NSNumber(value: Bool.random())
            label.order = NSNumber(value: 100)
            label.isSoftDeleted = Bool.random()

            let email = Email(context: context)
            email.userID = label.userID
            email.contactID = String.randomString(100)
            email.emailID = String.randomString(100)
            email.email = String.randomString(100)
            email.name = String.randomString(100)
            email.defaults = NSNumber(value: 100)
            email.order = NSNumber(value: 1000)
            email.type = String.randomString(100)
            email.lastUsedTime = Date()

            let email2 = Email(context: context)
            email2.userID = label.userID
            email2.contactID = String.randomString(100)
            email2.emailID = String.randomString(100)
            email2.email = String.randomString(100)
            email2.name = String.randomString(100)
            email2.defaults = NSNumber(value: 100)
            email2.order = NSNumber(value: 2000)
            email2.type = String.randomString(100)
            email2.lastUsedTime = Date()

            let mutableSet = label.mutableSetValue(forKey: Label.Attributes.emails)
            mutableSet.add(email)
            mutableSet.add(email2)

            return LabelEntity(label: label)
        }
    }

    static func makeMocks(num: Int) -> [LabelEntity] {
        return (0..<num).map { _ in makeMock() }
    }
}
