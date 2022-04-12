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

import Groot
import ProtonCore_DataModel
import ProtonCore_Networking
import XCTest
@testable import ProtonMail

final class MessageDecrypterTests: XCTestCase {
    private var mockUserData: UserManager!
    private var decrypter: MessageDecrypter!
    private var coreDataService: CoreDataService!
    private var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        self.coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        self.testContext = coreDataService.rootSavingContext
        self.mockUserData = UserManager(api: APIServiceSpy(), role: .member)
        self.decrypter = MessageDecrypter(userDataSource: mockUserData)
    }

    override func tearDownWithError() throws {
        self.mockUserData = nil
        self.decrypter = nil
        self.coreDataService = nil
        self.testContext = nil
    }
}

// MARK: decryption message
extension MessageDecrypterTests {
    func testGetAddressKeys_emptyAddressID() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1.rawValue)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2.rawValue)
        let address = Address(addressID: "aaa", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 2, keys: [key1, key2])

        self.mockUserData.userInfo.userAddresses = [address]
        let keys = self.decrypter.getAddressKeys(for: nil)
        XCTAssertEqual(keys.count, 2)
        XCTAssertEqual(keys[0].keyID, "key1")
        XCTAssertEqual(keys[1].keyID, "key2")
    }

    func testGetAddressKeys_hasAddressID() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1.rawValue)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2.rawValue)
        let address = Address(addressID: "address", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 1, keys: [key1])
        let address2 = Address(addressID: "address2", domainID: nil, email: "test2@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 1, keys: [key2])
        
        self.mockUserData.userInfo.userAddresses = [address, address2]
        var keys = self.decrypter.getAddressKeys(for: "address")
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0].keyID, "key1")
        keys = self.decrypter.getAddressKeys(for: "address2")
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0].keyID, "key2")
    }

    func verifyHTMLMIMEBody(processedBody: String, mimeAttachments: [MimeAttachment]) {
        XCTAssertEqual(mimeAttachments.count, 2)
        guard let imageAttachment = mimeAttachments.first(where: { $0.fileName == "image.png" }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(processedBody.contains(check: MessageDecrypterTestData.imageAttachmentHTMLElement()),
                       true)
        let manager = FileManager.default
        XCTAssertEqual(imageAttachment.disposition, "Content-Disposition: inline; filename=image.png\n")
        XCTAssertEqual(imageAttachment.mimeType, "image/png")
        XCTAssertEqual(manager.fileExists(atPath: imageAttachment.localUrl?.path ?? ""),
                       true)
        guard let wordAttachment = mimeAttachments.first(where: { $0.fileName == "file-sample_100kB.doc" }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(wordAttachment.disposition, "Content-Disposition: attachment; filename=file-sample_100kB.doc\n")
        XCTAssertEqual(wordAttachment.mimeType, "application/msword")
        XCTAssertEqual(manager.fileExists(atPath: wordAttachment.localUrl?.path ?? ""),
                       true)
        try? manager.removeItem(atPath: imageAttachment.localUrl?.path ?? "")
        try? manager.removeItem(atPath: wordAttachment.localUrl?.path ?? "")
    }

    func testProcessMIMEBody_html_success() throws {
        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let (processedBody, mimeAttachments) = self.decrypter.postProcessMIME(body: body)
        self.verifyHTMLMIMEBody(processedBody: processedBody, mimeAttachments: mimeAttachments)
    }

    func testProcessMIMEBody_plainText_success() throws {
        let body = MessageDecrypterTestData.decryptedPlainTextMimeBody()
        let (processedBody, mimeAttachments) = self.decrypter.postProcessMIME(body: body)
        XCTAssertEqual(mimeAttachments.count, 2)
        guard let imageAttachment = mimeAttachments.first(where: { $0.fileName == "image.png" }) else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(body, processedBody)
        XCTAssertEqual(processedBody, MessageDecrypterTestData.procedMIMEPlainTextBody())
        let manager = FileManager.default
        XCTAssertEqual(imageAttachment.disposition, "Content-Disposition: inline; filename=image.png\n")
        XCTAssertEqual(imageAttachment.mimeType, "image/png")
        XCTAssertEqual(manager.fileExists(atPath: imageAttachment.localUrl?.path ?? ""),
                       true)
        guard let wordAttachment = mimeAttachments.first(where: { $0.fileName == "file-sample_100kB.doc" }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(wordAttachment.disposition, "Content-Disposition: attachment; filename=file-sample_100kB.doc\n")
        XCTAssertEqual(wordAttachment.mimeType, "application/msword")
        XCTAssertEqual(manager.fileExists(atPath: wordAttachment.localUrl?.path ?? ""),
                       true)
        try? manager.removeItem(atPath: imageAttachment.localUrl?.path ?? "")
        try? manager.removeItem(atPath: wordAttachment.localUrl?.path ?? "")
    }

    func testPGPInline_plainText() throws {
        let body = "A & B ' <>"
        let (processedBody, mimeAttachments) = self.decrypter
            .postProcessPGPInline(isPlainText: true,
                                  isMultipartMixed: false,
                                  body: body)
        XCTAssertEqual(mimeAttachments.isEmpty, true)
        XCTAssertEqual(processedBody, "A &amp; B &#039; &lt;&gt;")
    }

    func testPGPInline_plainTextWithHTML() throws {
        let body = "<html><head></head><body> A & B ' <>"
        let (processedBody, mimeAttachments) = self.decrypter
            .postProcessPGPInline(isPlainText: true,
                                  isMultipartMixed: false,
                                  body: body)
        XCTAssertEqual(mimeAttachments.isEmpty, true)
        XCTAssertEqual(processedBody, body)
    }

    func testPGPInline_multipartMixed() {
        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let (processedBody, mimeAttachments) = self.decrypter
            .postProcessPGPInline(isPlainText: false,
                                  isMultipartMixed: true,
                                  body: body)
        self.verifyHTMLMIMEBody(processedBody: processedBody, mimeAttachments: mimeAttachments)
    }

    func testPGPInline_elseCase() {
        let body = "test body"
        let (processedBody, mimeAttachments) = self.decrypter
            .postProcessPGPInline(isPlainText: false,
                                  isMultipartMixed: false,
                                  body: body)
        XCTAssertEqual(mimeAttachments.isEmpty, true)
        XCTAssertEqual(processedBody, body)
    }
}

// MARK: copy message
extension MessageDecrypterTests {
    func testGetFirstAddressKey() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1.rawValue)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2.rawValue)
        let address = Address(addressID: "aaa", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 2, keys: [key1, key2])

        self.mockUserData.userInfo.userAddresses = [address]
        var key = self.decrypter.getFirstAddressKey(for: nil)
        XCTAssertNil(key)

        key = self.decrypter.getFirstAddressKey(for: "aaa")
        XCTAssertEqual(key?.keyID, "key1")
    }

    func testDuplicateMessage() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        let duplicated = self.decrypter.duplicate(fakeMsg, context: self.testContext)
        XCTAssertEqual(fakeMsg.toList, duplicated.toList)
        XCTAssertEqual(fakeMsg.title, duplicated.title)
        XCTAssertEqual(fakeMsg.body, duplicated.body)
        XCTAssertNotEqual(fakeMsg.time, duplicated.time)
        
    }
}
