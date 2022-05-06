// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

import XCTest
@testable import ProtonMail

class PushNotificationPayloadTests: XCTestCase {

    // MARK: init

    func testInit_withRemoteNotification_whenHasAllFields() {
        let payload = PushNotificationPayloadTestData.remoteNotificationAllField.jsonFormattedToDictionary()

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.uid == "w2gv5zsa58biuqtedgnyc12aabd5xkpx")
        XCTAssert(model.viewMode == 1)
        XCTAssert(model.unreadMessages == 14)
        XCTAssert(model.unreadConversations == 12)
        XCTAssert(model.action == "message_created")
        XCTAssert(model.encryptedMessage == PushNotificationPayloadTestData.encryptedMessageFormatted)
    }

    func testInit_withLocalNotification_sessionRevoked() {
        let payload = LocalNotificationService.Categories.sessionRevoked.payload()

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.category == "LocalNotificationService.Categories.sessionRevoked")
        XCTAssert(model.localNotification == true)
    }

    func testInit_withLocalNotification_failedToSend() {
        let messageId = "dummy_message_id"
        let payload = LocalNotificationService.Categories.failedToSend.payload(with: messageId)

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.category == "LocalNotificationService.Categories.failedToSend")
        XCTAssert(model.messageId == messageId)
        XCTAssert(model.localNotification == true)
    }

    // MARK: isLocalNotification

    func testIsLocalNotification_withRemoteNotification() {
        let payload = PushNotificationPayloadTestData.remoteNotificationAllField.jsonFormattedToDictionary()

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.isLocalNotification == false)
    }

    func testIsLocalNotification_withLocalNotification_sessionRevoked() {
        let payload = LocalNotificationService.Categories.sessionRevoked.payload()

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.isLocalNotification == true)
    }

    func testIsLocalNotification_withLocalNotification_failedToSend() {
        let messageId = "dummy_message_id"
        let payload = LocalNotificationService.Categories.failedToSend.payload(with: messageId)

        let model = try! PushNotificationPayload(userInfo: payload)
        XCTAssert(model.isLocalNotification == true)
    }
}

private enum PushNotificationPayloadTestData {

    static let encryptedMessageValue =
    """
    -----BEGIN PGP MESSAGE-----

    Version: ProtonMail

    wV4DpsJdFLWS5pgSAQdA2keSTTV4UT0uQZlEbqs9i7nAlZtn3doPdVj3qoLU
    4UAw6EhlEsK7iNySPdgNKDo0hkcGDDrzesGnIwpB6OPfP5W81X/6wSF0EkvO
    CC0ABwlY0sDRAdD6hciQR2TEdooNaJn8EvdWxigYQzV5OQp1bquc3uhTDEf4
    AG7B96v7eLXwDrAhvGHJ1cP8Tp21a6sCHA2SpsrOEr4Gd+ygzPxzP4Pt6BRk
    yyjugeFsaGraNiXukY9esFZ9/JwlgncEPmzanDISH/3tVzpj5MND6MH8GIBg
    M7BsR7onU3pIgFzogJnFqTe88PFJ63y0sIIV98le/OPeOFUoTaDp0v7GsPBz
    z8ADmhX72Yiad+Ac8tekAIWLPeipUY+dMTikH9iKTRg3UleOeBtCOvITpwBL
    cBgM56N2usRbLkg+ChlQ1qNwEDzNrpchg5z5lITAmCyXTwhRnRbTXllhgoB4
    iefUmN+vibNroU+oM8uCm23BblhM/VF7BHKdgGPmf5TnGPq9XV7b/GQt3czy
    Byajm3rNt8SKr2/H6ZbwkMQNTiodLEUPitgnO0EfT0QTeXvsuMlSRS+AyWjX
    yd5PC4iCKXHFUwtuwDvdvzobGsJ32xEhC9MKhEGkn7Ih3cwpFrk1tArS1+4N
    XsBH44w=
    =GzKr

    -----END PGP MESSAGE-----
    """

    /// Used to avoid JSONSerialization crashing
    static var encryptedMessageFormatted: String {
        encryptedMessageValue.components(separatedBy: .newlines).joined()
    }

    static let remoteNotificationAllField =
    """
    {
      "UID": "w2gv5zsa58biuqtedgnyc12aabd5xkpx",
      "unreadConversations": 12,
      "unreadMessages": 14,
      "viewMode": 1,
      "action": "message_created",
      "encryptedMessage": "\(encryptedMessageFormatted)",
      "aps": {
        "alert": "New message received",
        "badge": 5,
        "mutable-content": 1
      }
    }
    """
}

private extension String {

    func jsonFormattedToDictionary() -> [AnyHashable:Any] {
        return try! JSONSerialization.jsonObject(with: Data(self.utf8), options: []) as! [AnyHashable:Any]
   }
}

