//
//  BackgroundSaveTests.swift
//  Proton MailTests
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.
//

import XCTest
@testable import ProtonMail
import CoreData
import Groot

class BackgroundSaveTests: XCTestCase {

    var testMessage: Message!
    var coreDataService: CoreDataService!
    var rootContext: NSManagedObjectContext!
    var mainContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        rootContext = coreDataService.rootSavingContext
        mainContext = coreDataService.mainContext

        let parsedObject = testMessageMetaData.parseObjectAny()!
        testMessage = try GRTJSONSerialization.object(withEntityName: "Message",
                                                      fromJSONDictionary: parsedObject,
                                                      in: rootContext) as? Message

        try rootContext.performAndWait {
            self.testMessage.userID = "userID"
            try self.rootContext.save()
        }
    }

    override func tearDown() {
        testMessage = nil
        coreDataService = nil
        rootContext = nil
        mainContext = nil

        super.tearDown()
    }

    func testBackgroundSaveAndFetchingInMainContext() throws {
        let backgroundContext = coreDataService.rootSavingContext
        let modifyStartTime = Date()
        for i in 0..<2000 {
            backgroundContext.perform {
                let object = try? backgroundContext.existingObject(with: self.testMessage.objectID) as? Message
                object?.body = "\(i)"
                try? backgroundContext.save()
            }
        }

        let expect = expectation(description: "Wait for right value")
        var endTime: Date?
        var startTime: Date?
        var loopCount = 0

        mainContext.perform {
            startTime = Date()
            var shouldContinue = true

            while shouldContinue {
                loopCount += 1
                let object = try? self.mainContext.existingObject(with: self.testMessage.objectID) as? Message
                XCTAssertEqual(object?.messageID, "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==")
                if object?.body == "1999" {
                    shouldContinue = false
                    endTime = Date()
                }
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)

        let matchEndTime = try XCTUnwrap(endTime)
        let matchStartTime = try XCTUnwrap(startTime)
        XCTAssertEqual(loopCount, 1)

        print("Result: loop count: \(loopCount)")
        print("Result: Data modify start Time: \(modifyStartTime) nano: \(modifyStartTime.nanosecond)")
        print("Result: Time of Match Start: \(matchStartTime) nano: \(matchStartTime.nanosecond)")
        print("Result: Time of Match End: \(matchEndTime) nano: \(matchEndTime.nanosecond)")
        let diff = matchEndTime.timeIntervalSince1970 - matchStartTime.timeIntervalSince1970
        print("Result: Diff \(diff)")
    }
}
