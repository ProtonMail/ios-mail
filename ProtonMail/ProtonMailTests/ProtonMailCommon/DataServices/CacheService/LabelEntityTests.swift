// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class LabelEntityTests: XCTestCase {

    var contextProviderMock: MockCoreDataContextProvider!
    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
    }

    override func tearDown() {
        super.tearDown()
        contextProviderMock = nil
    }

    func testInit() throws {
        // Prepare test data
        let label = Label(context: contextProviderMock.rootSavingContext)
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

        let email = Email(context: contextProviderMock.rootSavingContext)
        email.userID = label.userID
        email.contactID = String.randomString(100)
        email.emailID = String.randomString(100)
        email.email = String.randomString(100)
        email.name = String.randomString(100)
        email.defaults = NSNumber(value: 100)
        email.order = NSNumber(value: 1000)
        email.type = String.randomString(100)
        email.lastUsedTime = Date()

        let email2 = Email(context: contextProviderMock.rootSavingContext)
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

        let result = LabelEntity(label: label)

        XCTAssertEqual(result.userID.rawValue, label.userID)
        XCTAssertEqual(result.labelID.rawValue, label.labelID)
        XCTAssertEqual(result.parentID.rawValue, label.parentID)
        XCTAssertEqual(result.name, label.name)
        XCTAssertEqual(result.color, label.color)
        XCTAssertEqual(result.type.rawValue, label.type.intValue)
        XCTAssertEqual(result.sticky, label.sticky.boolValue)
        XCTAssertEqual(result.order, label.order.intValue)
        XCTAssertEqual(result.path, label.path)
        XCTAssertEqual(result.notify, label.notify.boolValue)
        XCTAssertEqual(result.isSoftDeleted, label.isSoftDeleted)
        XCTAssertEqual(result.objectID.rawValue, label.objectID)

        let emails = try XCTUnwrap(result.emailRelations)
        XCTAssertEqual(emails.count, 2)

        let sortEmails = emails.sorted(by: { $0.order < $1.order })
        XCTAssertEqual(emails, sortEmails)

        let emailEntity1 = try XCTUnwrap(emails.first)
        XCTAssertEqual(emailEntity1.contactID.rawValue, email.contactID)
        XCTAssertEqual(emailEntity1.userID.rawValue, email.userID)
        XCTAssertEqual(emailEntity1.emailID.rawValue, email.emailID)
        XCTAssertEqual(emailEntity1.email, email.email)
        XCTAssertEqual(emailEntity1.name, email.name)
        XCTAssertEqual(emailEntity1.defaults, email.defaults.boolValue)
        XCTAssertEqual(emailEntity1.order, email.order.intValue)
        XCTAssertEqual(emailEntity1.type, email.type)
        XCTAssertEqual(emailEntity1.lastUsedTime, email.lastUsedTime)

        let emailEntity2 = try XCTUnwrap(emails.last)
        XCTAssertEqual(emailEntity2.contactID.rawValue, email2.contactID)
        XCTAssertEqual(emailEntity2.userID.rawValue, email2.userID)
        XCTAssertEqual(emailEntity2.emailID.rawValue, email2.emailID)
        XCTAssertEqual(emailEntity2.email, email2.email)
        XCTAssertEqual(emailEntity2.name, email2.name)
        XCTAssertEqual(emailEntity2.defaults, email2.defaults.boolValue)
        XCTAssertEqual(emailEntity2.order, email2.order.intValue)
        XCTAssertEqual(emailEntity2.type, email2.type)
        XCTAssertEqual(emailEntity2.lastUsedTime, email2.lastUsedTime)
    }

}
