//
//  Encryptor+Streaming.swift
//  ProtonCore-KeyManager - Created on 07/08/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreCryptoGoInterface

extension Encryptor {
    public enum SigncryptError: Error {
        case cleartextFileHasNoSize
        case invalidPublicKey
        case invalidPrivateKey
    }

    public static func encryptStream(_ cleartextUrl: URL,
                                     _ cyphertextUrl: URL,
                                     _ nodeKey: String,
                                     _ nodePassphrase: String,
                                     _ contentKeyPacket: Data,
                                     _ chunkSize: Int) throws -> Data
    {
        // prepare files
        if FileManager.default.fileExists(atPath: cyphertextUrl.path) {
            try FileManager.default.removeItem(at: cyphertextUrl)
        }
        FileManager.default.createFile(atPath: cyphertextUrl.path, contents: Data(), attributes: nil)

        let readFileHandle = try FileHandle(forReadingFrom: cleartextUrl)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cyphertextUrl)
        defer { writeFileHandle.closeFile() }

        guard let size = try FileManager.default.attributesOfItem(atPath: cleartextUrl.path)[.size] as? Int else {
            throw SigncryptError.cleartextFileHasNoSize
        }

        // cryptography

        var error: NSError?
        let sessionKey = CryptoGo.HelperDecryptSessionKey(nodeKey, Data(nodePassphrase.utf8), contentKeyPacket, &error)
        guard error == nil else { throw error! }

        let hash = try Encryptor.encryptBinaryStream(sessionKey!, nil, readFileHandle, writeFileHandle, size, chunkSize)
        return hash
    }

    // Marin: Adding this method defeats the point of giving the session key and key rings directly. Which were used to avoid decrypting and building the objects for each block
    public static func signStream(_ nodePublicKey: String,
                                  _ addressPrivateKey: String,
                                  _ addressPassphrase: String,
                                  _ plaintextFile: URL) throws -> String
    {
        guard var encryptionKey = CryptoGo.CryptoKey(fromArmored: nodePublicKey) else {
            throw SigncryptError.invalidPublicKey
        }

        if encryptionKey.isPrivate() {
            encryptionKey = try encryptionKey.toPublic()
        }

        guard let encryptionKeyRing = CryptoGo.CryptoKeyRing(encryptionKey) else {
            throw SigncryptError.invalidPublicKey
        }

        guard let signKeyLocked = CryptoGo.CryptoKey(fromArmored: addressPrivateKey) else {
            throw SigncryptError.invalidPrivateKey
        }

        let signKeyUnlocked = try signKeyLocked.unlock(Data(addressPassphrase.utf8))

        guard let signKeyRing = CryptoGo.CryptoKeyRing(signKeyUnlocked) else {
            throw SigncryptError.invalidPrivateKey
        }

        let readFileHandle = try FileHandle(forReadingFrom: plaintextFile)
        let hash = try signStream(signKeyRing, encryptionKeyRing, readFileHandle)

        if #available(macOSApplicationExtension 10.15, macOS 15.0, *) {
            try readFileHandle.close()
        }

        return hash
    }
}

extension Encryptor {
    private static func encryptBinaryStream(_ sessionKey: CryptoSessionKey,
                                            _ signKeyRing: CryptoKeyRing?,
                                            _ blockFile: FileHandle,
                                            _ ciphertextFile: FileHandle,
                                            _ totalSize: Int,
                                            _ bufferSize: Int ) throws -> Data
    {

        let ciphertextWriter = CryptoGo.HelperMobile2GoWriterWithSHA256(FileMobileWriter(file: ciphertextFile))!
        let plaintextWriter = try sessionKey.encryptStream(ciphertextWriter, plainMessageMetadata: nil, sign: signKeyRing)

        var offset = 0
        var n = 0
        while offset < totalSize {
            try autoreleasepool {
                blockFile.seek(toFileOffset: UInt64(offset))
                let currentBufferSize = offset + bufferSize > totalSize ? totalSize - offset : bufferSize
                let currentBuffer = blockFile.readData(ofLength: currentBufferSize)
                try plaintextWriter.write(currentBuffer, n: &n)
                offset += n
            }
        }

        try plaintextWriter.close()

        return ciphertextWriter.getSHA256()!
    }

    private static func signStream(_ signKeyRing: CryptoKeyRing,
                                   _ encryptKeyRing: CryptoKeyRing,
                                   _ plaintextFile: FileHandle) throws -> String
    {
        var error: NSError?

        let plaintextReader = CryptoGo.HelperMobile2GoReader(FileMobileReader(file: plaintextFile))

        let encSignature = try signKeyRing.signDetachedEncryptedStream(plaintextReader, encryptionKeyRing: encryptKeyRing)

        let encSignatureArmored = encSignature.getArmored(&error)

        guard error == nil else {
            throw error!
        }
        return encSignatureArmored
    }
}
