// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import class ProtonCoreDataModel.Key

enum AttachmentCrypto {

    static func encrypt(attachment: AttachmentEntity, with key: Key) throws -> (Data, URL)? {
        var attachment = attachment
        var path = attachment.filePathByLocalURL()
        if let clearData = attachment.fileData, path == nil {
            try attachment.writeToLocalURL(data: clearData)
            path = attachment.filePathByLocalURL()
        }
        guard let localURL = path else { return nil }

        var error: NSError?
        let key = CryptoGo.CryptoNewKeyFromArmored(key.publicKey, &error)
        if let err = error { throw err }

        let keyRing = CryptoGo.CryptoNewKeyRing(key, &error)
        if let err = error { throw err }

        guard let aKeyRing = keyRing else {  return nil }

        let cipherURL = localURL.appendingPathExtension("cipher")
        let keyPacket = try AttachmentStreamingEncryptor.encryptStream(localURL, cipherURL, aKeyRing, 2_000_000)

        return (keyPacket, cipherURL)
    }

    static func sign(
        attachment: AttachmentEntity,
        key: Key,
        userKeys: [ArmoredKey],
        passphrase: Passphrase
    ) -> Data? {
        do {
            let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys, mailboxPassphrase: passphrase)
            let signingKey = SigningKey(privateKey: ArmoredKey(value: key.privateKey), passphrase: addressKeyPassphrase)
            let dataToSign: Data
            if let fileData = attachment.fileData {
                dataToSign = fileData
            } else if let localURL = attachment.filePathByLocalURL() {
                dataToSign = try Data(contentsOf: localURL)
            } else {
                return nil
            }
            let armoredSignature = try Sign.signDetached(signingKey: signingKey, plainData: dataToSign)
            return armoredSignature.value.unArmor
        } catch {
            return nil
        }
    }
}
