// Copyright (c) 2021 Proton Technologies AG
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

final class PushNotificationHandlerTests: XCTestCase {
    var sut: PushNotificationHandler!

    override func setUp() {
        super.setUp()
        sut = PushNotificationHandler()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func notificationRequest(identifier: String, sender: String, body: String) -> UNNotificationRequest {
        let plainTextPayload = """
        {"data":{"title":"ProtonMail","subtitle":"","body":"\(body)","sender":{"Name":"\(sender)","Address":"foo@bar.com","Group":""},"vibrate":1,"sound":1,"largeIcon":"large_icon","smallIcon":"small_icon","badge":\(Int.random(in: 0..<100)),"messageId":"\(UUID().uuidString)"},"type":"email","version":2}
        """
        let encryptedPayload = try! Crypto().encrypt(plainText: plainTextPayload, publicKey: EncryptionKitProviderMock().publicKey)!
        let userInfo: [NSString: Any?] = [
            "UID": EncryptionKitProviderMock.UID,
            "unreadConversations": nil,
            "unreadMessages": Int.random(in: 0..<100),
            "viewMode": Int.random(in: 0...1),
            "encryptedMessage": encryptedPayload,
            "aps": ["alert": "New message received",
                    "badge": Int.random(in: 0..<100),
                    "mutable-content": 1]
        ]
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo as [AnyHashable: Any]
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: nil)
        return request
    }

    func testHandlerShouldCallPushPingBackService() {
        let mock = URLSessionMock()
        let identifier = UUID().uuidString
        let notificationRequest = UNNotificationRequest(identifier: identifier,
                                                        content: UNNotificationContent(),
                                                        trigger: nil)
        let expectation = self.expectation(description: "URLSession call expectation")
        sut.handle(session: mock,
                   request: notificationRequest) { _ in
            XCTAssertEqual(mock.dataTaskCallCount, 1)
            XCTAssertEqual(mock.dataTaskArgsRequest[0].httpMethod, "POST")
            XCTAssertEqual(mock.dataTaskArgsRequest[0].value(forHTTPHeaderField: "x-pm-appversion"), "iOS_\(Bundle.main.majorVersion)")
            XCTAssertEqual(mock.dataTaskArgsRequest[0].value(forHTTPHeaderField: "Content-Type"), "application/json;charset=utf-8")
            XCTAssertNotNil(mock.dataTaskArgsRequest[0].url?.absoluteString)
            XCTAssertEqual(mock.dataTaskArgsRequest[0].url?.absoluteString, NotificationPingBack.endpoint)
            let decodedBody = try! JSONDecoder().decode(NotificationPingBackBody.self, from: mock.dataTaskArgsRequest[0].httpBody!)
            XCTAssertEqual(decodedBody.notificationId, identifier)
            XCTAssertFalse(decodedBody.decrypted)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHandlerShouldProperlyDecryptNotificationAndCallPushPingBackService() {
        let testBody = "Test subject"
        let testSender = "A sender"
        let identifier = UUID().uuidString
        let request = notificationRequest(identifier: identifier, sender: testSender, body: testBody)
        let mock = URLSessionMock()
        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(session: mock,
                   request: request,
                   encryptionKitProvider: EncryptionKitProviderMock()) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, EncryptionKitProviderMock.UID)
            XCTAssertEqual(decryptedContent.title, testSender)
            XCTAssertEqual(decryptedContent.body, testBody)
            XCTAssertEqual(mock.dataTaskCallCount, 1)
            XCTAssertEqual(mock.dataTaskArgsRequest[0].httpMethod, "POST")
            XCTAssertEqual(mock.dataTaskArgsRequest[0].value(forHTTPHeaderField: "x-pm-appversion"), "iOS_\(Bundle.main.majorVersion)")
            XCTAssertEqual(mock.dataTaskArgsRequest[0].value(forHTTPHeaderField: "Content-Type"), "application/json;charset=utf-8")
            XCTAssertNotNil(mock.dataTaskArgsRequest[0].url?.absoluteString)
            XCTAssertEqual(mock.dataTaskArgsRequest[0].url?.absoluteString, NotificationPingBack.endpoint)
            let decodedBody = try! JSONDecoder().decode(NotificationPingBackBody.self, from: mock.dataTaskArgsRequest[0].httpBody!)
            XCTAssertEqual(decodedBody.notificationId, identifier)
            XCTAssertTrue(decodedBody.decrypted)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

final class MockDataTask: URLSessionDataTask {
    var completionHandler: (Data?, URLResponse?, Error?) -> Void
    init(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
    }

    override func resume() {
        delay(0.1) {
            self.completionHandler(nil, nil, nil)
        }
    }
}

class URLSessionMock: URLSessionProtocol {
    var dataTaskCallCount = 0
    var dataTaskArgsRequest: [URLRequest] = []
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            dataTaskCallCount += 1
            dataTaskArgsRequest.append(request)
            return MockDataTask(completionHandler: completionHandler)
    }
}
