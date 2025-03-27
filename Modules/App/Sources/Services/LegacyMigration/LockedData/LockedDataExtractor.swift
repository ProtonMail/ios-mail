// Copyright (c) 2025 Proton Technologies AG
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

enum LockedDataExtractor {
    static func decryptAndDecode<T: Decodable>(data encryptedData: Data, using key: Data) throws -> [T] {
        let iv = encryptedData[0..<16]
        let ciphertext = encryptedData[16...]
        let decryptedArchives = try AES.CTR.decrypt(ciphertext: ciphertext, key: key, iv: iv)
        return try PropertyListDecoder().decode([T].self, from: decryptedArchives)
    }
}
