//
//  PushDataTests.swift
//  ProtonMail - Created on 30/11/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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
