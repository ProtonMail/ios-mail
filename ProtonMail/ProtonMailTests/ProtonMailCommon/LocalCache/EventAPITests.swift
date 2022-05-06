//
//  EventAPITests.swift
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

import XCTest
@testable import ProtonMail

class EventAPITests: XCTestCase {
    
    func testEventCheckResponseParsing() throws {
        let data = eventTestDatawithDeleteConversation.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = EventCheckResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        
        XCTAssertEqual(sut.eventID, "YavOMCsY_G_OM2ti21cBlKbY-wVO-LaxvvLwGFM5duj3RpswhVBMFkepPg==")
        XCTAssertEqual(sut.refresh, RefreshStatus(rawValue: 0))
        XCTAssertEqual(sut.more, 0)
        XCTAssertEqual(sut.messages?.count, 3)
        
        XCTAssertNil(sut.contacts)
        XCTAssertNil(sut.contactEmails)
        XCTAssertNil(sut.labels)
        XCTAssertNil(sut.user)
        XCTAssertNil(sut.userSettings)
        XCTAssertNil(sut.mailSettings)
        XCTAssertNil(sut.addresses)
        XCTAssertEqual(sut.messageCounts?.count, 11)
        
        XCTAssertEqual(sut.conversations?.count, 1)
        
        XCTAssertEqual(sut.conversationCounts?.count, 11)
        
        XCTAssertEqual(sut.usedSpace, 157621062)
        XCTAssertEqual(sut.notices, [])
    }
}
