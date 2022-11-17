//
//  PushDataTests.swift
//  Proton Mail - Created on 30/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
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

@testable import ProtonMail
import XCTest

class PushContentTests: XCTestCase {
    func testInit_fullPayloadTypeEmail() {
        let payload = PushContentTestsData.fullPayloadTypeEmail
        let pushContent = try! PushContent(json: payload)

        XCTAssertEqual(pushContent.data.sender.address, "rosencrantz@proton.me")
        XCTAssertEqual(pushContent.data.sender.name, "Anatoly Rosencrantz")
        XCTAssertEqual(pushContent.data.badge, 11)
        XCTAssertEqual(pushContent.data.body, "Push push")
        XCTAssertEqual(pushContent.data.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
        XCTAssertEqual(pushContent.remoteNotificationType, .email)
    }

    func testInit_fullPayloadTypeOpenUrl() {
        let payload = PushContentTestsData.fullPayloadTypeOpenUrl
        let pushContent = try! PushContent(json: payload)

        XCTAssertEqual(pushContent.data.sender.address, "abuse@proton.me")
        XCTAssertEqual(pushContent.data.sender.name, "ProtonMail")
        XCTAssertEqual(pushContent.data.badge, 4)
        XCTAssertEqual(pushContent.data.body, "New login to your account on ProtonCalendar for web.")
        XCTAssertEqual(pushContent.data.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
        XCTAssertEqual(pushContent.remoteNotificationType, .openUrl)
    }

    func testInit_minimalPayload() {
        let payload = PushContentTestsData.minimalPayload
        let pushContent = try! PushContent(json: payload)

        XCTAssertEqual(pushContent.data.sender.address, "rosencrantz@proton.me")
        XCTAssertEqual(pushContent.data.sender.name, "Anatoly Rosencrantz")
        XCTAssertEqual(pushContent.data.badge, 11)
        XCTAssertEqual(pushContent.data.body, "Push push")
        XCTAssertEqual(pushContent.data.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
    }

    func testInit_noSenderName() {
        let payload = PushContentTestsData.payloadWithoutSenderName
        let pushContent = try! PushContent(json: payload)

        XCTAssertEqual(pushContent.data.sender.address, "rosencrantz@proton.me")
        XCTAssertEqual(pushContent.data.sender.name, "")
        XCTAssertEqual(pushContent.data.badge, 11)
        XCTAssertEqual(pushContent.data.body, "Push push")
        XCTAssertEqual(pushContent.data.messageId, "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==")
    }

    func testInit_whenUnknownType() {
        let payload = PushContentTestsData.fullPayloadUnexpectedType
        let content = try! PushContent(json: payload)

        // An unknown type should not make PushContent fail, but RemoteNotificationType will be `nil`
        XCTAssert(content.type == "whatever unexpected type")
        XCTAssert(content.remoteNotificationType == nil)
    }
}

private enum PushContentTestsData {
    static let fullPayloadTypeEmail =
        """
        {
          "data": {
            "title": "ProtonMail",
            "subtitle": "",
            "body": "Push push",
            "sender": {
              "Name": "Anatoly Rosencrantz",
              "Address": "rosencrantz@proton.me",
              "Group": ""
            },
            "vibrate": 1,
            "sound": 1,
            "largeIcon": "large_icon",
            "smallIcon": "small_icon",
            "badge": 11,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="
          },
          "type": "email",
          "version": 2
        }
        """

    static let fullPayloadTypeOpenUrl =
        """
        {
          "data": {
            "body": "New login to your account on ProtonCalendar for web.",
            "sender": {
              "Name": "ProtonMail",
              "Address": "abuse@proton.me",
              "Group": ""
            },
            "badge": 4,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==",
            "url": "https://proton.me/support/knowledge-base/display-name-and-signature/"
          },
          "type": "open_url"
        }
        """

    static let fullPayloadUnexpectedType =
        """
        {
          "data": {
            "title": "ProtonMail",
            "subtitle": "",
            "body": "Push push",
            "sender": {
              "Name": "Anatoly Rosencrantz",
              "Address": "rosencrantz@proton.me",
              "Group": ""
            },
            "vibrate": 1,
            "sound": 1,
            "largeIcon": "large_icon",
            "smallIcon": "small_icon",
            "badge": 11,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="
          },
          "type": "whatever unexpected type",
          "version": 2
        }
        """

    static let minimalPayload =
        """
        {
          "data": {
            "body": "Push push",
            "sender": {
              "Name": "Anatoly Rosencrantz",
              "Address": "rosencrantz@proton.me"
            },
            "badge": 11,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="
          }
        }
        """

    static let payloadWithoutSenderName =
        """
        {
          "data": {
            "body": "Push push",
            "sender": {
              "Name": "",
              "Address": "rosencrantz@proton.me"
            },
            "badge": 11,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug=="
          }
        }
        """
}
