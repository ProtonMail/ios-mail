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

import ProtonCore_Hash
import ProtonCore_Keymaker

final class SenderImageCache {
    static let shared = SenderImageCache()

    struct CacheKey {
        let rawValue: String
    }

    private let encryptedCache: EncryptedCache

    private init() {
        encryptedCache = .init(
            maxDiskSize: Constants.SenderImage.cacheDiskSizeLimitInBytes,
            subdirectory: "me.proton.senderImage"
        )
    }

    func senderImage(forURL url: String) throws -> Data? {
        let key = cacheKey(forURL: url)

        guard let data = try encryptedCache.decryptedData(forKey: key.rawValue) else {
            return nil
        }

        return data
    }

    func setSenderImage(_ data: Data, forURL url: String) throws {
        let key = cacheKey(forURL: url)
        try encryptedCache.encryptAndSaveData(data, forKey: key.rawValue)
    }

    func removeSenderImage(forURL url: String) {
        let key = cacheKey(forURL: url)
        encryptedCache.removeData(forKey: key.rawValue)
    }

    func purge() {
        encryptedCache.purge()
    }

    private func cacheKey(forURL url: String) -> CacheKey {
        CacheKey(rawValue: url.sha512)
    }
}
