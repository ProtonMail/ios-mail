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

import Foundation

enum AttachmentDecrypterError: Error {
    case failDecodingKeyPacket
    case failEncodingString
    case foundNilData
}

struct AttachmentDecrypter {

    static func decryptAndEncode(fileUrl: URL, attachmentKeyPacket: String?, userKeys: UserKeys) throws -> String {
        let data = try decrypt(fileUrl: fileUrl, attachmentKeyPacket: attachmentKeyPacket, userKeys: userKeys)
        return data.base64EncodedString(options: .lineLength64Characters)
    }

    static func decryptAndEncodePublicKey(
        fileUrl: URL,
        attachmentKeyPacket: String?,
        userKeys: UserKeys
    ) throws -> String {
        let data = try decrypt(fileUrl: fileUrl, attachmentKeyPacket: attachmentKeyPacket, userKeys: userKeys)
        guard let encodedString = String(data: data, encoding: .utf8) else {
            throw AttachmentDecrypterError.failEncodingString
        }
        return encodedString
    }

    static func decrypt(fileUrl: URL, attachmentKeyPacket: String?, userKeys: UserKeys) throws -> Data {
        guard
            let keyPacket = attachmentKeyPacket,
            let keyData = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0))
        else {
            throw AttachmentDecrypterError.failDecodingKeyPacket
        }

        let attachment: Data = try Data(contentsOf: fileUrl)

        if let decryptedData = try attachment.decryptAttachment(
            keyPackage: keyData,
            userKeys: userKeys.privateKeys,
            passphrase: userKeys.mailboxPassphrase,
            keys: userKeys.addressesPrivateKeys
        ) {
            return decryptedData
        } else {
            throw AttachmentDecrypterError.foundNilData
        }
    }
}
