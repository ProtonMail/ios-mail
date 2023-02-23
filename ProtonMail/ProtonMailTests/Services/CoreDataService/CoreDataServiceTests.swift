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

import CoreData
import XCTest

@testable import ProtonMail

class CoreDataServiceTests: XCTestCase {
    private var sut: CoreDataService!
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        persistentContainer = MockCoreDataStore.testPersistentContainer
        sut = CoreDataService(container: persistentContainer)
    }

    override func tearDownWithError() throws {
        sut = nil
        persistentContainer = nil

        try super.tearDownWithError()
    }

    func testWrite_changesAreSavedAndCanBeRead() throws {
        try sut.createNewMessage()

        let newMessageBody: String = try sut.read { context in
            let message = try XCTUnwrap(
                context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
            )
            return message.body
        }

        XCTAssertEqual(newMessageBody, "initial body")
    }

    // this test can be deleted once/if we remove all access beside `read` and `write` methods
    func testWrite_changesAreImmediatelyReflectedInOtherBackgroundContextsFromTheSamePersistentContainer() throws {
        try sut.createNewMessage()

        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true

        let messageSeenInBackgroundContext = try backgroundContext.performAndWait {
            try XCTUnwrap(
                backgroundContext.managedObjectWithEntityName(
                    Message.Attributes.entityName,
                    matching: [:]
                ) as? Message
            )
        }

        backgroundContext.performAndWait {
            XCTAssertEqual(messageSeenInBackgroundContext.body, "initial body")
        }

        try sut.modifyMessage(with: messageSeenInBackgroundContext.objectID)

        backgroundContext.performAndWait {
            XCTAssertEqual(messageSeenInBackgroundContext.body, "updated body")
        }
    }

    // this test can be deleted once/if we remove all NSFetchedResultsControllers
    func testRead_contextCanBeStoredInFetchedResultsControllerAndIsStillUpdated() throws {
        try sut.createNewMessage()

        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true)]

        let fetchedResultsController: NSFetchedResultsController<Message> = sut.read { context in
            NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        }

        try fetchedResultsController.performFetch()

        let fetchedMessage = fetchedResultsController.object(at: IndexPath(row: 0, section: 0))

        fetchedResultsController.managedObjectContext.performAndWait {
            XCTAssertEqual(fetchedMessage.body, "initial body")
        }

        try sut.modifyMessage(with: fetchedMessage.objectID)

        fetchedResultsController.managedObjectContext.performAndWait {
            XCTAssertEqual(fetchedMessage.body, "updated body")
        }
    }

    // delete this test once we remove mainContext completely
    func testWrite_changesAreNotPropagatedToMainContextAndItNeedsToBeExplicitlyRefreshed() throws {
        let mainContext = sut.mainContext

        try sut.createNewMessage()

        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        try fetchedResultsController.performFetch()

        let fetchedMessage = fetchedResultsController.object(at: IndexPath(row: 0, section: 0))

        XCTAssertEqual(fetchedMessage.body, "initial body")

        try sut.modifyMessage(with: fetchedMessage.objectID)

        XCTAssertEqual(fetchedMessage.body, "initial body")

        mainContext.refreshAllObjects()

        XCTAssertEqual(fetchedMessage.body, "updated body")
    }

    // delete this test once we remove rootSavingContext completely
    func testRead_changesSavedToRootSavingContextAreDetected() throws {
        try sut.createNewMessage()

        let (createdMessage, retainedContext): (Message, NSManagedObjectContext) = try sut.read { context in
            let message = try XCTUnwrap(
                context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
            )
            return (message, context)
        }

        sut.performAndWaitOnRootSavingContext { context in
            do {
                let editableMessage = try XCTUnwrap(
                    context.managedObjectWithEntityName(
                        Message.Attributes.entityName,
                        matching: [:]
                    ) as? Message
                )

                editableMessage.body = "updated body"

                if let error = context.saveUpstreamIfNeeded() {
                    throw error
                }
            } catch {
                XCTFail("\(error)")
            }
        }

        let updatedBody = retainedContext.performAndWait {
            createdMessage.body
        }

        XCTAssertEqual(updatedBody, "updated body")
    }
}

private extension CoreDataService {
    func createNewMessage() throws {
        try write { context in
            let newMessage = Message(context: context)
            newMessage.body = "initial body"
        }
    }

    func modifyMessage(with objectID: NSManagedObjectID) throws {
        try write { context in
            let editableMessage = try XCTUnwrap(context.existingObject(with: objectID) as? Message)
            editableMessage.body = "updated body"
        }
    }
}
