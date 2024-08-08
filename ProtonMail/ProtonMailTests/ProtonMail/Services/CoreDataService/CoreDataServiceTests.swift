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
import ProtonCoreTestingToolkitUnitTestsCore
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

        await waitUntilChangesAreMergedIntoMainContext()

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 1)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 0)

        try sut.write { context in
            let message = try XCTUnwrap(Message.messageForMessageID("bar", inManagedObjectContext: context))
            message.body = "updated bar body"
        }

        await waitUntilChangesAreMergedIntoMainContext()

        XCTAssertEqual(fooDelegate.controllerDidChangeContentStub.callCounter, 1)
        XCTAssertEqual(barDelegate.controllerDidChangeContentStub.callCounter, 1)

        try sut.write { context in
            let request = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            let messages = try request.execute()

            for message in messages {
                context.delete(message)
            }
        }

        await waitUntilChangesAreMergedIntoMainContext()

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

    func testNestedRead_canAccessPendingChangesBeforeWriteSavesContext() throws {
        try sut.write { writeContext in
            let messageInWriteContext = Message(context: writeContext)
            messageInWriteContext.messageID = "1"

            let messageIDBeforeTheEndOfTheWriteBlock = try self.sut.read { context in
                let message = try XCTUnwrap(
                    context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
                )
                return message.messageID
            }

            XCTAssertEqual(messageIDBeforeTheEndOfTheWriteBlock, "1")
        }
    }

    func testNestedWrite_canOperateOnObjectFromOuterWrite() throws {
        try sut.write { outerContext in
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

        let messageIDAfterAllWrites = try sut.read { context in
            let message = try XCTUnwrap(
                context.managedObjectWithEntityName(Message.Attributes.entityName, matching: [:]) as? Message
            )
            return message.messageID
        }

        XCTAssertEqual(messageIDAfterAllWrites, "1234")
    }

    private func waitUntilChangesAreMergedIntoMainContext() async {
        await sleep(milliseconds: 50)
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

    /*
     The scenario is that if there's a long-running `write` in progress, and then we call `deleteAllData` from
     somewhere else, the deletion needs to be queued as any other operation to ensure it also removes the data from that
     `write`.

     Otherwise the call to `context.save()` might restore everything that was there before, by dumping the contents of
     memory (i.e. the context) to the persistent store.
     */
    func testDeleteAllData_ifCalledSimultaneouslyWithWrite_ensuresDataDoesntPersist() throws {
        let sut = CoreDataStore.shared
        try sut.initialize()
        let coreDataService = CoreDataService(container: sut.container)

        let deletionExecuted = expectation(description: "Deletion executed")
        let deletionCompleted = expectation(description: "Deletion completed")
        let writeHasCompleted = expectation(description: "Write has completed")

        // Schedule a deletion to occur while the block below is in progress
        Task {
            try await Task.sleep(for: .milliseconds(150))
            deletionExecuted.fulfill()

            await coreDataService.deleteAllData()
            deletionCompleted.fulfill()
        }

        /*
         This block will start immediately, but will be executing over 0.3 seconds, so the deletion started above will
         hit while this block is in progress.

         It's important to note that the 2nd Message (bar) is scheduled to be created _after_ the sleep, so technically
         after the deletion is called.

         However, it will not be saved, as the deletion will be queued as a call to write would.
         */
        try coreDataService.write { context in
            let fooMessage = Message(context: context)
            fooMessage.messageID = "foo"

            Thread.sleep(forTimeInterval: 0.3)

            let barMessage = Message(context: context)
            barMessage.messageID = "bar"
            writeHasCompleted.fulfill()
        }

        wait(for: [deletionExecuted, writeHasCompleted, deletionCompleted], timeout: 1, enforceOrder: true)

        let idsOfStoredMessages = try coreDataService.read { _ in
            try NSFetchRequest<Message>(entityName: Message.Attributes.entityName).execute().map(\.messageID)
        }

        XCTAssertEqual(idsOfStoredMessages, [])
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
