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

import XCTest

@testable import ProtonMail

final class CoreDataStoreTests: XCTestCase {
    override func tearDownWithError() throws {
        CoreDataStore.deleteDataStore()

        try super.tearDownWithError()
    }

    func testDeletingDataStore_clearsEntities() throws {
        let sut = CoreDataStore.shared
        let container = sut.defaultContainer
        let coordinator = container.persistentStoreCoordinator

        let context = container.newBackgroundContext()
        try context.performAndWait {
            let message = Message(context: context)
            message.messageID = "foo"
            try context.save()
        }

        try container.viewContext.performAndWait {
            let messages = try Message.makeFetchRequest().execute()
            XCTAssertEqual(messages.map(\.messageID), ["foo"])
        }

        CoreDataStore.deleteDataStore()

        try container.viewContext.performAndWait {
            let messages = try Message.makeFetchRequest().execute()
            XCTAssertEqual(messages.map(\.messageID), [])
        }
    }

    func testDeletingDataStore_doesNotBreakSavingNewEntities() throws {
        let sut = CoreDataStore.shared
        let container = sut.defaultContainer

        CoreDataStore.deleteDataStore()

        let context = container.newBackgroundContext()
        try context.performAndWait {
            let message = Message(context: context)
            message.messageID = "foo"
            try context.save()
        }

        try container.viewContext.performAndWait {
            let messages = try Message.makeFetchRequest().execute()
            XCTAssertEqual(messages.map(\.messageID), ["foo"])
        }
    }
}
