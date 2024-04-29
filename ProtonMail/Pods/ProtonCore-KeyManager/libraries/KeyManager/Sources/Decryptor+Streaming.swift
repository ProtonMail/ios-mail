//
//  Decryptor+Streaming.swift
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
import ProtonCoreDataModel
import ProtonCoreUtilities

extension Decryptor {

    // Marin: Adding this method defeats the point of giving the session key and key rings directly. Which were used to avoid decrypting and building the objects for each block

    @available(*, deprecated, renamed: "Decryptor.decryptStream(encryptedFile:decryptedFile:decryptionKeys:keyPacket:verificationKeys:signature:chunckSize:removeClearTextFileIfAlreadyExists:)")
    public static func decryptStream(_ cyphertextUrl: URL,
                                     _ cleartextUrl: URL,
                                     _ decryptionKeys: [DecryptionKey],
                                     _ keyPacket: Data,
                                     _ verificationKeys: [String],
                                     _ signature: String,
                                     _ chunckSize: Int) throws {
        try decryptStream(encryptedFile: cyphertextUrl,
                          decryptedFile: cleartextUrl,
                          decryptionKeys: decryptionKeys,
                          keyPacket: keyPacket,
                          verificationKeys: verificationKeys,
                          signature: signature,
                          chunckSize: chunckSize,
                          removeClearTextFileIfAlreadyExists: true)
    }

    public static func decryptStream(encryptedFile cyphertextUrl: URL,
                                     decryptedFile cleartextUrl: URL,
                                     decryptionKeys: [DecryptionKey],
                                     keyPacket: Data,
                                     verificationKeys: [String],
                                     signature: String,
                                     chunckSize: Int,
                                     removeClearTextFileIfAlreadyExists: Bool = false) throws
    {
        // prepare files
        if FileManager.default.fileExists(atPath: cleartextUrl.path) {
            if removeClearTextFileIfAlreadyExists {
                try FileManager.default.removeItem(at: cleartextUrl)
            } else {
                throw Errors.outputFileAlreadyExists
            }
        }
        FileManager.default.createFile(atPath: cleartextUrl.path, contents: Data(), attributes: nil)

        let readFileHandle = try FileHandle(forReadingFrom: cyphertextUrl)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cleartextUrl)
        defer { writeFileHandle.closeFile() }
        // cryptography

        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }
        let sessionKey = try decryptionKeyRing.decryptSessionKey(keyPacket)

        try Decryptor.decryptBinaryStream(sessionKey, nil, readFileHandle, writeFileHandle, chunckSize)

        let verifyFileHandle = try FileHandle(forReadingFrom: cleartextUrl)
        defer { verifyFileHandle.closeFile() }
        guard let verificationKeyRing = try buildPublicKeyRing(armoredKeys: verificationKeys) else {
            throw Errors.couldNotCreateKeyRing
        }

        try Decryptor.verifyStream(verificationKeyRing, decryptionKeyRing, verifyFileHandle, signature)
    }
}

// MARK: - CryptoKeyRing decryption helpers
extension Decryptor {
    private static func verifyStream(_ verifyKeyRing: CryptoKeyRing,
                                     _ decryptKeyRing: CryptoKeyRing,
                                     _ plaintextFile: FileHandle,
                                     _ encSignatureArmored: String) throws
    {
        let plaintextReader = CryptoGo.HelperMobile2GoReader(FileMobileReader(file: plaintextFile))

        let encSignature = CryptoGo.CryptoPGPMessage(fromArmored: encSignatureArmored)

        try verifyKeyRing.verifyDetachedEncryptedStream(
            plaintextReader,
            encryptedSignature: encSignature,
            decryptionKeyRing: decryptKeyRing,
            verifyTime: CryptoGo.CryptoGetUnixTime()
        )
    }

    private static func decryptBinaryStream(_ sessionKey: CryptoSessionKey,
                                            _ verifyKeyRing: CryptoKeyRing?,
                                            _ ciphertextFile: FileHandle,
                                            _ blockFile: FileHandle,
                                            _ bufferSize: Int) throws
    {

        let ciphertextReader = CryptoGo.HelperMobile2GoReader(FileMobileReader(file: ciphertextFile))

        let plaintextMessageReader = try sessionKey.decryptStream(
            ciphertextReader,
            verifyKeyRing: verifyKeyRing,
            verifyTime: CryptoGo.CryptoGetUnixTime()
        )

        let reader = CryptoGo.HelperGo2IOSReader(plaintextMessageReader)!
        var isEOF: Bool = false
        while !isEOF {
            try autoreleasepool {
                let result = try reader.read(bufferSize)
                blockFile.write(result.data ?? Data())
                isEOF = result.isEOF
            }
        }

        if verifyKeyRing != nil {
            try plaintextMessageReader.verifySignature()
        }
    }

}
