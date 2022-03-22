//
//  ConversationEventTests.swift
//  ProtonMailTests - Created on 2020.
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

@testable import ProtonMail
class ConversationEventTests: XCTestCase {

    func testConversationEventInit() throws {
        let data = testConversationEvent.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationEvent(event: responseDictionary)
        XCTAssertNotNil(sut)
        
        XCTAssertEqual(sut!.action, 3)
        XCTAssertEqual(sut!.ID, "7roRxUKBEBHTl22odgEWglj-47jRh4A6i_uR4UNfVCmu7c9JUX_az_zCmFR10yw6Nu40z-Pl8QRm-dzoVb6OdQ==")
        XCTAssertNotNil(sut!.conversation)
    }

}
