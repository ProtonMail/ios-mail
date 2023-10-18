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
import ProtonCoreCryptoGoInterface

final class HashHelper {
    private let keyDerivationNumIterations = 32_768

    /// Given a string, it returns a salted and hashed value
    ///
    /// The hash algorithm uses a Key Derivation Function that is deliberately slow to challenge brute force attacks
    func saltAndHash(value: String, with salt: Data) throws -> Data {
        var error: NSError?
        guard let hashData = CryptoGo.SubtleDeriveKey(value, salt, keyDerivationNumIterations, &error) else {
            throw HashError.hashFail
        }
        return hashData
    }

    /// Returns a cryptographically secure random value
    func generateRandomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            throw HashError.randomBytesFail
        }
        return Data(bytes)
    }

    private enum HashError: String, LocalizedError {
        case randomBytesFail = "generating cryptographically secure random value failed"
        case hashFail = "creating hash failed"

        var errorDescription: String? {
            "HashError: \(rawValue)"
        }
    }
}
