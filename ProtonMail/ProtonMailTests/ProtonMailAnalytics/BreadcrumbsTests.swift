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

import XCTest
@testable import ProtonMailAnalytics

class BreadcrumbsTests: XCTestCase {
    var sut: Breadcrumbs!
    
    let firstMessage = "first"
    let secondMessage = "second"
    let thirdMessage = "third"
    var severalMessages: [String] {
        [firstMessage, secondMessage, thirdMessage]
    }

    override func setUp() {
        super.setUp()
        sut = Breadcrumbs()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCrumbs_whenNoMessagesHaveBeenAdded() {
        XCTAssertNil(sut.crumbs(for: .generic))
    }

    func testAdd_whenOnlyOneMessageIsAdded() {
        sut.add(message: firstMessage, to: .generic)

        XCTAssert(sut.crumbs(for: .generic)?.count == 1)
        XCTAssert(sut.crumbs(for: .generic)![0].message == firstMessage)
    }

    func testAdd_whenSeveralMessagesAreAdded() {
        severalMessages.forEach { msg in
            sut.add(message: msg, to: .generic)
        }

        XCTAssert(sut.crumbs(for: .generic)?.count == severalMessages.count)
        XCTAssert(sut.crumbs(for: .generic)!.map(\.message) == severalMessages)
    }

    func testAdd_whenMoreThanMaxMessagesAreAdded() {
        let offset = 10
        let totalMessages = sut.maxCrumbs + offset
        for i in 1..<totalMessages {
            sut.add(message: String(i), to: .generic)
        }

        XCTAssert(sut.crumbs(for: .generic)?.count == sut.maxCrumbs)
        XCTAssert(sut.crumbs(for: .generic)?.first?.message == String(totalMessages - sut.maxCrumbs))
        XCTAssert(sut.crumbs(for: .generic)?.last?.message == String(totalMessages - 1))
    }

    func testAdd_whenMessageAddedToDifferentEvents() {
        sut.add(message: firstMessage, to: .generic)
        sut.add(message: firstMessage, to: .malformedConversationRequest)
        sut.add(message: secondMessage, to: .generic)
        sut.add(message: thirdMessage, to: .generic)

        XCTAssert(sut.crumbs(for: .generic)?.count == 3)
        XCTAssert(sut.crumbs(for: .malformedConversationRequest)?.count == 1)
        XCTAssert(sut.crumbs(for: .malformedConversationRequest)?.first?.message == firstMessage)
    }

    func testTrace_whenNoMessagesHaveBeenAdded() {
        XCTAssertNil(sut.trace(for: .generic))
    }

    func testTrace_whenSeveralMessagesAreAdded() {
        severalMessages.forEach { msg in
            sut.add(message: msg, to: .generic)
        }

        let crumbs: [Breadcrumbs.Crumb] = sut.crumbs(for: .generic)!
        let expectedOutput = "\(crumbs[2].description)\n\(crumbs[1].description)\n\(crumbs[0].description)"
        XCTAssert(sut.trace(for: .generic) == expectedOutput)
    }

    func testTrace_whenMessageAddedToDifferentEvents() {
        sut.add(message: firstMessage, to: .generic)
        sut.add(message: firstMessage, to: .malformedConversationRequest)
        sut.add(message: secondMessage, to: .generic)

        let crumbsGeneric: [Breadcrumbs.Crumb] = sut.crumbs(for: .generic)!
        let crumbsMalformed: [Breadcrumbs.Crumb] = sut.crumbs(for: .malformedConversationRequest)!

        XCTAssert(sut.trace(for: .generic) == "\(crumbsGeneric[1].description)\n\(crumbsGeneric[0].description)")
        XCTAssert(sut.trace(for: .malformedConversationRequest) == "\(crumbsMalformed[0].description)")
    }
}
