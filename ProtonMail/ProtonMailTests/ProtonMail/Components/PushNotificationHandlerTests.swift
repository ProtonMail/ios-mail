// Copyright (c) 2021 Proton AG
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
import ProtonCore_Crypto
@testable import ProtonMail

final class PushNotificationHandlerTests: XCTestCase {
    var sut: PushNotificationHandler!
    private var mockEncryptionKitProvider: EncryptionKitProviderMock!
    private var mockUrlSession: URLSessionMock!

    override func setUp() {
        super.setUp()
        mockUrlSession = URLSessionMock()
        mockEncryptionKitProvider = EncryptionKitProviderMock()
        let dependencies = PushNotificationHandler.Dependencies(
            urlSession: mockUrlSession,
            encryptionKitProvider: mockEncryptionKitProvider
        )
        sut = PushNotificationHandler(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockUrlSession = nil
        mockEncryptionKitProvider = nil
    }

    func testHandle_shouldCallPushPingBackService() {
        let identifier = UUID().uuidString
        let notificationRequest = UNNotificationRequest(
            identifier: identifier,
            content: UNNotificationContent(),
            trigger: nil
        )
        let expectation = self.expectation(description: "URLSession call expectation")
        sut.handle(request: notificationRequest) { _ in
            self.assertUrlSession(self.mockUrlSession, notificationId: identifier, expectedDecryptedBodyValue: false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHandle_shouldProperlyDecryptNotificationAndCallPushPingBackService_whenIsEmailNotification() {
        let testBody = "Test subject"
        let testSender = "A sender"
        let identifier = UUID().uuidString
        let request = mailNotificationRequest(identifier: identifier, sender: testSender, body: testBody)

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, self.mockEncryptionKitProvider.UID)
            XCTAssertEqual(decryptedContent.title, testSender)
            XCTAssertEqual(decryptedContent.body, testBody)
            self.assertUrlSession(self.mockUrlSession, notificationId: identifier, expectedDecryptedBodyValue: true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHandle_shouldProperlyDecryptNotificationAndCallPushPingBackService_whenIsOpenUrlNotification() {
        let expectedSender = "ProntonMail"
        let expectedBody = "New sign in to your account"
        let identifier = UUID().uuidString
        let request = mailNotificationRequest(identifier: identifier, sender: expectedSender, body: expectedBody)

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, self.mockEncryptionKitProvider.UID)
            XCTAssertEqual(decryptedContent.title, expectedSender)
            XCTAssertEqual(decryptedContent.body, expectedBody)
            self.assertUrlSession(self.mockUrlSession, notificationId: identifier, expectedDecryptedBodyValue: true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

private extension PushNotificationHandlerTests {

    private func assertUrlSession(_ session: URLSessionMock, notificationId: String, expectedDecryptedBodyValue: Bool) {
        XCTAssertEqual(self.mockUrlSession.dataTaskCallCount, 1)
        XCTAssertEqual(self.mockUrlSession.dataTaskArgsRequest[0].httpMethod, "POST")
        XCTAssertEqual(self.mockUrlSession.dataTaskArgsRequest[0].value(forHTTPHeaderField: "x-pm-appversion"), "iOS_\(Bundle.main.majorVersion)")
        XCTAssertEqual(self.mockUrlSession.dataTaskArgsRequest[0].value(forHTTPHeaderField: "Content-Type"), "application/json;charset=utf-8")
        XCTAssertNotNil(self.mockUrlSession.dataTaskArgsRequest[0].url?.absoluteString)
        XCTAssertEqual(self.mockUrlSession.dataTaskArgsRequest[0].url?.absoluteString, NotificationPingBack.endpoint)
        let decodedBody = try! JSONDecoder().decode(NotificationPingBackBody.self, from: self.mockUrlSession.dataTaskArgsRequest[0].httpBody!)
        XCTAssertEqual(decodedBody.notificationId, notificationId)
        XCTAssertEqual(decodedBody.decrypted, expectedDecryptedBodyValue)
    }

    private func mailNotificationRequest(identifier: String, sender: String, body: String) -> UNNotificationRequest {
        let plainTextPayload = """
        {
          "data": {
            "title": "ProtonMail",
            "subtitle": "",
            "body": "\(body)",
            "sender": {
              "Name": "\(sender)",
              "Address": "foo@bar.com",
              "Group": ""
            },
            "vibrate": 1,
            "sound": 1,
            "largeIcon": "large_icon",
            "smallIcon": "small_icon",
            "badge": \(Int.random(in: 0..<100)),
            "messageId": "\(UUID().uuidString)"
          },
          "type": "email",
          "version": 2
        }
        """
        let encryptedPayload = try! Crypto().encryptNonOptional(plainText: plainTextPayload, publicKey: mockEncryptionKitProvider.publicKey)
        let userInfo: [NSString: Any?] = [
            "UID": mockEncryptionKitProvider.UID,
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

    private func openUrlNotificationRequest(identifier: String, sender: String, body: String) -> UNNotificationRequest {
        let encryptedPayload = PushEncryptedMessageTestData
            .openUrlNotification(with: mockEncryptionKitProvider, sender: sender, body: body)
        let userInfo: [NSString: Any?] = [
            "UID": mockEncryptionKitProvider.UID,
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
}

private final class MockDataTask: URLSessionDataTask {
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

private class URLSessionMock: URLSessionProtocol {
    var dataTaskCallCount = 0
    var dataTaskArgsRequest: [URLRequest] = []

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        dataTaskCallCount += 1
        dataTaskArgsRequest.append(request)
        return MockDataTask(completionHandler: completionHandler)
    }
}
