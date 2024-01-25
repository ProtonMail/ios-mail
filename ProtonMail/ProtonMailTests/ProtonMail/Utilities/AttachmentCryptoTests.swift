// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
@testable import ProtonMail
import XCTest

final class AttachmentCryptoTests: XCTestCase {
    func testSign_signatureCanBeVerified() throws {
        let keyPair = try CryptoKeyHelper.makeKeyPair()
        let addressKey = CryptoKeyHelper.makeAddressKey(userKey: keyPair)

        let data = try XCTUnwrap(String.randomString(20).data(using: .utf8))
        let attachment = AttachmentEntity(id: "111", rawMimeType: "", attachmentType: .text, name: "", userID: "", messageID: "", isSoftDeleted: false, fileData: data, fileSize: .init(value: data.dataSize), keyChanged: false, objectID: .init(rawValue: .init()), order: 0, contentId: nil)

        let signatureData = try XCTUnwrap(
            AttachmentCrypto.sign(
                attachment: attachment,
                key: addressKey,
                userKeys: [.init(value: keyPair.privateKey)],
                passphrase: .init(value: keyPair.passphrase)
            )
        )

        var error: NSError?
        let pgpSignature = CryptoGo.CryptoPGPSignature(signatureData)?.getArmored(&error)
        XCTAssertNil(error)
        let pgpSignatureUnwarped = try XCTUnwrap(pgpSignature)

        let result = try Sign.verifyDetached(
            signature: ArmoredSignature(value: pgpSignatureUnwarped),
            plainData: data,
            verifierKey: .init(value: addressKey.publicKey)
        )
        XCTAssertTrue(result)
    }
}
