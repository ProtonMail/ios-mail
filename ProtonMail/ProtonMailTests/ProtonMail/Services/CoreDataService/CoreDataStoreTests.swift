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
import XCTest

@testable import ProtonMail

final class CoreDataStoreTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        CoreDataStore.deleteDataStore()
    }

    override func tearDownWithError() throws {
        CoreDataStore.deleteDataStore()

        try super.tearDownWithError()
    }

    func testInitialize_whenCalledMultipleTimes_doesntCrash() throws {
        let sut = CoreDataStore.shared

        try sut.initialize()
        try sut.initialize()
    }

    func testDeletingDataStore_clearsEntities() throws {
        let sut = CoreDataStore.shared
        let container = sut.container

        let context = container.newBackgroundContext()
        try context.performAndWait {
            let message = Message(context: context)
            message.messageID = "foo"
            try context.save()
        }

        XCTAssertEqual(try sut.storedMessageIDs(), ["foo"])

        CoreDataStore.deleteDataStore()

        XCTAssertEqual(try sut.storedMessageIDs(), [])
    }

    func testDeletingDataStore_doesNotBreakSavingNewEntities() throws {
        let sut = CoreDataStore.shared
        let container = sut.container

        CoreDataStore.deleteDataStore()

        let context = container.newBackgroundContext()
        try context.performAndWait {
            let message = Message(context: context)
            message.messageID = "foo"
            try context.save()
        }

        XCTAssertEqual(try sut.storedMessageIDs(), ["foo"])
    }
}

private extension CoreDataStore {
    func storedMessageIDs() throws -> [String] {
        try container.viewContext.performAndWait {
            try NSFetchRequest<Message>(entityName: Message.Attributes.entityName).execute().map(\.messageID)
        }
    }
}
