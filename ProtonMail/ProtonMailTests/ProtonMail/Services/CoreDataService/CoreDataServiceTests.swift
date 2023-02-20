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
import ProtonCore_TestingToolkit
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
    func testWrite_changesArePropagatedToMainContext() async throws {
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

        mainContext.performAndWait {
            XCTAssertEqual(fetchedMessage.body, "initial body")
        }

        try sut.modifyMessage(with: fetchedMessage.objectID)

        try await waitUntilChangesAreMergedIntoMainContext()

        mainContext.performAndWait {
            XCTAssertEqual(fetchedMessage.body, "updated body")
        }
    }

    func testWrite_onlyNotifiesRelevantFetchedResultsControllers() async throws {
        try sut.write { context in
            let fooMessage = Message(context: context)
            fooMessage.body = "initial foo body"
            fooMessage.messageID = "foo"

            let barMessage = Message(context: context)
            barMessage.body = "initial bar body"
            barMessage.messageID = "bar"
        }

        let (fooFetchedResultsController, fooDelegate) = try makeFetchedResultsControllerAndDelegate(messageID: "foo")
        let (barFetchedResultsController, barDelegate) = try makeFetchedResultsControllerAndDelegate(messageID: "bar")

        XCTAssertEqual(fooFetchedResultsController.fetchedObjects?.count, 1)
        XCTAssertEqual(barFetchedResultsController.fetchedObjects?.count, 1)

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 0)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 0)

        try sut.write { context in
            let message = try XCTUnwrap(Message.messageForMessageID("foo", inManagedObjectContext: context))
            message.body = "updated foo body"
        }

        try await waitUntilChangesAreMergedIntoMainContext()

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 1)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 0)

        try sut.write { context in
            let message = try XCTUnwrap(Message.messageForMessageID("bar", inManagedObjectContext: context))
            message.body = "updated bar body"
        }

        try await waitUntilChangesAreMergedIntoMainContext()

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 1)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 1)

        try sut.write { context in
            let request = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            let messages = try request.execute()

            for message in messages {
                context.delete(message)
            }
        }

        try await waitUntilChangesAreMergedIntoMainContext()

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 2)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 2)
    }

    func testWrite_isReentrant() throws {
        let outerWillStart = expectation(description: "outer write will start")
        let outerIsRunning = expectation(description: "outer write is running")
        let outerHasFinished = expectation(description: "outer write has finished")
        let innerWillStart = expectation(description: "inner write will start")
        let innerIsRunning = expectation(description: "inner write is running")
        let innerHasFinished = expectation(description: "inner write has finished")

        DispatchQueue.global().async {
            do {
                outerWillStart.fulfill()

                try self.sut.write { _ in
                    outerIsRunning.fulfill()

                    innerWillStart.fulfill()

                    try self.sut.write { _ in
                        Thread.sleep(forTimeInterval: 0.2)
                        innerIsRunning.fulfill()
                    }

                    innerHasFinished.fulfill()
                }

                outerHasFinished.fulfill()
            } catch {
                XCTFail("\(error)")
            }
        }

        wait(
            for: [outerWillStart, outerIsRunning, innerWillStart, innerIsRunning, innerHasFinished, outerHasFinished],
            timeout: 1,
            enforceOrder: true
        )
    }

    func testWrite_savesContextAtTheEndOfTheBlock() throws {
        try sut.write { writeContext in
            let messageInWriteContext = Message(context: writeContext)
            messageInWriteContext.messageID = "1"

            // Notice that by the time this `read` occurs, `writeContext` hasn't been saved yet.
            self.sut.read { readContext in
                XCTAssertNil(readContext.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]))
            }
        }

        // Now that we're out of the `write` block, the context has been saved, so the messageID is available.
        let messageIDAfterTheEndOfTheWriteBlock = try sut.read { context in
            let message = try XCTUnwrap(
                context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
            )
            return message.messageID
        }

        XCTAssertEqual(messageIDAfterTheEndOfTheWriteBlock, "1")
    }

    func testNestedWrite_canOperateOnObjectFromOuterWrite() throws {
        let exp = expectation(description: "operations have finished")

        DispatchQueue.global().async {
            do {
                try self.sut.write { outerContext in
                    let messageInOuterContext = Message(context: outerContext)
                    messageInOuterContext.messageID = "1"

                    try self.sut.write { _ in
                        messageInOuterContext.messageID = messageInOuterContext.messageID.appending("2")
                    }

                    messageInOuterContext.messageID = messageInOuterContext.messageID.appending("3")

                    try self.sut.write { _ in
                        messageInOuterContext.messageID = messageInOuterContext.messageID.appending("4")
                    }
                }
            } catch {
                XCTFail("\(error)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let messageIDAfterAllWrites = try sut.read { context in
            let message = try XCTUnwrap(
                context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
            )
            return message.messageID
        }

        XCTAssertEqual(messageIDAfterAllWrites, "1234")
    }

    private func waitUntilChangesAreMergedIntoMainContext() async throws {
        try await Task.sleep(nanoseconds: 5_000_000)
    }

    private func makeFetchedResultsControllerAndDelegate(messageID: String) throws -> (
        NSFetchedResultsController<Message>, MockFetchedResultsControllerDelegate
    ) {
        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: sut.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        let delegate = MockFetchedResultsControllerDelegate()

        fetchedResultsController.delegate = delegate

        try fetchedResultsController.performFetch()

        return (fetchedResultsController, delegate)
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

private class MockFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    @FuncStub(MockFetchedResultsControllerDelegate.controllerDidChangeContent) var controllerDidChangeContentStub
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        controllerDidChangeContentStub(controller)
    }
}
