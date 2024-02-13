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
            var attachment = attachment

            let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys, mailboxPassphrase: passphrase)
            let signingKey = SigningKey(privateKey: ArmoredKey(value: key.privateKey), passphrase: addressKeyPassphrase)

            var path = attachment.filePathByLocalURL()
            if let clearData = attachment.fileData, path == nil {
                try attachment.writeToLocalURL(data: clearData)
                path = attachment.filePathByLocalURL()
            }
            guard let path = path else { return nil }

            let armoredSignature = try Self.signDetachedStream(
                signerKey: signingKey,
                plainFile: path
            )
            return armoredSignature.value.unArmor
        } catch {
            return nil
        }
    }

    static private func signDetachedStream(
        signerKey: SigningKey,
        plainFile: URL
    ) throws -> ArmoredSignature {
        guard !signerKey.isEmpty else {
            throw SignError.invalidSigningKey
        }
        guard let signKeyLocked = CryptoGo.CryptoKey(fromArmored: signerKey.privateKey.value) else {
            throw SignError.invalidPrivateKey
        }
        let signKeyUnlocked = try signKeyLocked.unlock(signerKey.passphrase.data)
        guard let signKeyRing = CryptoGo.CryptoKeyRing(signKeyUnlocked) else {
            throw SignError.invalidPrivateKey
        }

        let readFileHandle = try FileHandle(forReadingFrom: plainFile)
        let plaintextReader = CryptoGo.HelperMobile2GoReader(CryptoFileReader(file: readFileHandle))
        let signature = try signKeyRing.signDetachedStream(withContext: plaintextReader, context: nil)
        try readFileHandle.close()

        var error: NSError?
        let result = signature.getArmored(&error)
        if let error = error {
            throw error
        }
        return ArmoredSignature(value: result)
    }
}

final private class CryptoFileReader: NSObject, HelperMobileReaderProtocol {
    enum Errors: Error {
        case failedToCreateCryptoHelper
    }

    let file: FileHandle

    init(file: FileHandle) {
        self.file = file
    }

    func read(_ max: Int) throws -> HelperMobileReadResult {
        let data = self.file.readData(ofLength: max)
        guard let helper = CryptoGo.HelperMobileReadResult(data.count, eof: data.isEmpty, data: data) else {
            assertionFailure("Failed to create Helper of Crypto - should not happen")
            throw Errors.failedToCreateCryptoHelper
        }
        return helper
    }
}
