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

import Crypto
import Foundation
import ProtonCore_Crypto

enum AttachmentStreamingEncryptor {}

extension AttachmentStreamingEncryptor {
    enum EncryptError: Error {
        case cleartextFileHasNoSize
        case unableToMakeWriter
    }

    static func encryptStream(_ clearTextUrl: URL,
                              _ cipherTextUrl: URL,
                              _ keyRing: CryptoKeyRing,
                              _ maxBlockChunkSize: Int) throws -> Data {
        if FileManager.default.fileExists(atPath: cipherTextUrl.path) {
            try FileManager.default.removeItem(at: cipherTextUrl)
        }
        FileManager.default.createFile(atPath: cipherTextUrl.path, contents: Data(), attributes: nil)

        let readFileHandle = try FileHandle(forReadingFrom: clearTextUrl)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cipherTextUrl)
        defer { writeFileHandle.closeFile() }

        guard let size = try FileManager.default.attributesOfItem(atPath: clearTextUrl.path)[.size] as? Int else {
            throw EncryptError.cleartextFileHasNoSize
        }

        let keyPacket = try AttachmentStreamingEncryptor.encryptBinaryStream(keyRing,
                                                                             readFileHandle,
                                                                             writeFileHandle,
                                                                             size,
                                                                             maxBlockChunkSize)
        return keyPacket
    }
}

extension AttachmentStreamingEncryptor {
    private static func encryptBinaryStream(_ encryptionKeyRing: CryptoKeyRing,
                                            _ blockFile: FileHandle,
                                            _ cipherTextFile: FileHandle,
                                            _ totalSize: Int,
                                            _ bufferSize: Int ) throws -> Data {

        guard let cipherTextWriter = HelperMobile2GoWriter(FileMobileWriter(file: cipherTextFile)) else {
            throw EncryptError.unableToMakeWriter
        }
        let plaintextWriter = try encryptionKeyRing.encryptSplitStream(cipherTextWriter,
                                                                       plainMessageMetadata: nil,
                                                                       sign: nil)

        var offset = 0
        var index = 0
        while offset < totalSize {
            try autoreleasepool {
                blockFile.seek(toFileOffset: UInt64(offset))
                let currentBufferSize = offset + bufferSize > totalSize ? totalSize - offset : bufferSize
                let currentBuffer = blockFile.readData(ofLength: currentBufferSize)
                try plaintextWriter.write(currentBuffer, n: &index)
                offset += index
            }
        }

        try plaintextWriter.close()

        return try plaintextWriter.getKeyPacket()
    }
}

final class FileMobileWriter: NSObject, CryptoWriterProtocol {
    var file: FileHandle

    init(file: FileHandle) {
        self.file = file
    }

    // swiftlint:disable identifier_name
    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        guard let b = b else {
            n?.pointee = 0
            return
        }
        self.file.write(b)
        n?.pointee = b.count
    }
    // swiftlint:enable identifier_name
}
