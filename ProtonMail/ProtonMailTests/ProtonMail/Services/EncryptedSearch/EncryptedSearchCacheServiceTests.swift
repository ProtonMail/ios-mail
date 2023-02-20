// Copyright (c) 2022 Proton Technologies AG
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

import Groot
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class EncryptedSearchCacheServiceTests: XCTestCase {
    var sut: EncryptedSearchCacheService!
    var userID: UserID!
    var cacheMock: MockEncryptedSearchGolangCache!
    var apiMock: APIServiceMock!

    override func setUp() {
        super.setUp()

        apiMock = .init()
        userID = .init(String.randomString(20))
        cacheMock = MockEncryptedSearchGolangCache()
        sut = .init(userID: userID)
        sut.setCache(cacheMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        cacheMock = nil
        apiMock = nil
    }

    func testBuildCacheForUser() {
        let params = EncryptedSearchDBParams(nil, table: nil, id: nil, time: nil, order: nil, labels: nil, initVector: nil, content: nil, contentFile: nil)
        let key = EncryptedSearchHelper.generateSearchIndexKey(userID: .init(String.randomString(10)))!
        let cipher = EncryptedSearchAESGCMCipher(key)

        let result = sut.buildCacheForUser(dbParams: params!,
                                           cipher: cipher!)

        XCTAssertNotNil(result)
        XCTAssertTrue(cacheMock.callDeleteAll.wasCalledExactlyOnce)
        XCTAssertTrue(cacheMock.callCacheIndex.wasCalledExactlyOnce)
    }

    func testDeleteCache() {
        sut.deleteCache()

        XCTAssertTrue(cacheMock.callDeleteAll.wasCalledExactlyOnce)
    }

    func testDeleteCachedMessage() throws {
        let msgID = MessageID(String.randomString(10))
        cacheMock.callDeleteMessage.bodyIs { _, _ in
            true
        }

        XCTAssertTrue(sut.deleteCachedMessage(messageID: msgID))

        let argument = try XCTUnwrap(cacheMock.callDeleteMessage.lastArguments?.a1)
        XCTAssertEqual(argument, msgID.rawValue)
    }

    func testIsCacheBuilt() {
        cacheMock.callIsBuilt.bodyIs { _ in
            true
        }

        XCTAssertTrue(sut.isCacheBuilt())

        XCTAssertTrue(cacheMock.callIsBuilt.wasCalledExactlyOnce)
    }

    func testUpdateCachedMessage() throws {
        let user = try prepareUser(apiMock: apiMock)
        let msg = try prepareEncryptedMessage(plaintextBody: "test", mimeType: .textPlain, user: user)

        sut.updateCachedMessage(message: msg, decryptedBody: "test")

        let argument = try XCTUnwrap(cacheMock.callUpdateCache.lastArguments?.a1)
        XCTAssertEqual(argument.messageID, msg.messageID.rawValue)
        XCTAssertEqual(argument.labelIDs, msg.getLabelIDs().map(\.rawValue).joined(separator: ","))
    }

    private func prepareEncryptedMessage(
        plaintextBody: String,
        mimeType: Message.MimeType,
        user: UserManager
    ) throws -> MessageEntity {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.addressKeys.toArmoredPrivateKeys[0],
            cleartext: plaintextBody
        ).value

        let parsedObject = testMessageDetailData.parseObjectAny()!
        let testContext = MockCoreDataStore.testPersistentContainer.newBackgroundContext()

        return try testContext.performAndWait {
            let messageObject = try XCTUnwrap(
                GRTJSONSerialization.object(
                    withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: testContext
                ) as? Message
            )
            messageObject.userID = "userID"
            messageObject.isDetailDownloaded = true
            messageObject.body = encryptedBody
            messageObject.mimeType = mimeType.rawValue
            return MessageEntity(messageObject)
        }
    }

    private func prepareUser(apiMock: APIServiceMock) throws -> UserManager {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: "1", privateKey: keyPair.privateKey)
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "",
            domainID: nil,
            email: "",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )

        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userAddresses = [address]
        user.userInfo.userKeys = [key]
        user.authCredential.mailboxpassword = keyPair.passphrase
        return user
    }
}
