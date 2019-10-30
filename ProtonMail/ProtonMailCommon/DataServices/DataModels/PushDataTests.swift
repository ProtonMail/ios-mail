//
//  PushDataTests.swift
//  ProtonMail - Created on 30/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import XCTest
@testable import ProtonMail

class PushDataTests: XCTestCase {

    func testFullPayload() {
        let payload = """
        {    "data": {        "title": "ProtonMail",        "subtitle": "",        "body": "Push push",        "sender": {            "Name": "Anatoly Rosencrantz",            "Address": "rosencrantz@protonmail.com",            "Group": ""        },        "vibrate": 1,        "sound": 1,        "largeIcon": "large_icon",        "smallIcon": "small_icon",        "badge": 11,        "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="    },    "type": "email",    "version": 2}
        """
        
        guard let pushData = PushData.parse(with: payload) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(pushData.sender.address, "rosencrantz@protonmail.com")
        XCTAssertEqual(pushData.sender.name, "Anatoly Rosencrantz")
        XCTAssertEqual(pushData.badge, 11)
        XCTAssertEqual(pushData.body, "Push push")
        XCTAssertEqual(pushData.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
    }
    
    func testMinimalPayload() {
        let payload = """
        {    "data": { "body": "Push push",        "sender": {            "Name": "Anatoly Rosencrantz",            "Address": "rosencrantz@protonmail.com"}, "badge": 11,        "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="    }}
        """
        
        guard let pushData = PushData.parse(with: payload) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(pushData.sender.address, "rosencrantz@protonmail.com")
        XCTAssertEqual(pushData.sender.name, "Anatoly Rosencrantz")
        XCTAssertEqual(pushData.badge, 11)
        XCTAssertEqual(pushData.body, "Push push")
        XCTAssertEqual(pushData.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
    }
    
    func testNoSenderName() {
        let payload = """
        {    "data": { "body": "Push push",        "sender": {            "Name": "",            "Address": "rosencrantz@protonmail.com"}, "badge": 11,        "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="    }}
        """
        
        guard let pushData = PushData.parse(with: payload) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(pushData.sender.address, "rosencrantz@protonmail.com")
        XCTAssertEqual(pushData.sender.name, "")
        XCTAssertEqual(pushData.badge, 11)
        XCTAssertEqual(pushData.body, "Push push")
        XCTAssertEqual(pushData.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
    }
    
}
