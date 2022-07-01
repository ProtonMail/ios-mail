//
//  ContextLabelCoreDataModelTests.swift
//  Proton MailTests - Created on 2020.
//
//
//  Copyright (c) 2020 Proton AG
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

import Groot
@testable import ProtonMail

class ContextLabelCoreDataModelTests: XCTestCase {
    func testContextLabelCreationInCoreData() throws {
        let coredata = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        let metaData = """
                                                          {
                                                             "ContextNumMessages":1,
                                                             "ContextNumUnread":0,
                                                             "ContextTime":1605861149,
                                                             "ContextSize":17711047,
                                                             "ContextNumAttachments":5,
                                                             "ID":"0"
                                                          }
        """
        guard let metaConversation = metaData.parseObjectAny() else {
            return
        }

        let managedObj = try GRTJSONSerialization.object(withEntityName: ContextLabel.Attributes.entityName,
                                                         fromJSONDictionary: metaConversation,
                                                         in: coredata.rootSavingContext) as? ContextLabel
        let error = coredata.rootSavingContext.saveUpstreamIfNeeded()
        XCTAssertNil(error)

        XCTAssertNotNil(managedObj)
        let contextLabel = managedObj!
        XCTAssertEqual(contextLabel.messageCount, 1)
        XCTAssertEqual(contextLabel.unreadCount, 0)
        XCTAssertEqual(contextLabel.time?.timeIntervalSince1970, 1605861149)
        XCTAssertEqual(contextLabel.size, 17711047)
        XCTAssertEqual(contextLabel.attachmentCount, 5)
        XCTAssertEqual(contextLabel.labelID, "0")
    }
}
