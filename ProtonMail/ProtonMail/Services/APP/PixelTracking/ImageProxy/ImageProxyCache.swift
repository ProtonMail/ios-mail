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

import ProtonCore_Hash
import ProtonCore_Keymaker

class ImageProxyCache {
    static let shared = ImageProxyCache()

    struct CacheKey {
        let rawValue: String
    }

    private let encryptedCache: EncryptedCache

    private init() {
        encryptedCache = EncryptedCache(
            maxDiskSize: Constants.ImageProxy.cacheDiskSizeLimitInBytes,
            subdirectory: "me.proton.imageproxy"
        )
    }

    func remoteImage(forURL remoteURL: SafeRemoteURL) throws -> RemoteImage? {
        let key = cacheKey(forURL: remoteURL)

        guard let data = try encryptedCache.decryptedData(forKey: key.rawValue) else {
            return nil
        }

        return try JSONDecoder().decode(RemoteImage.self, from: data)
    }

    func setRemoteImage(_ remoteImage: RemoteImage, forURL remoteURL: SafeRemoteURL) throws {
        let key = cacheKey(forURL: remoteURL)
        let data = try JSONEncoder().encode(remoteImage)
        try encryptedCache.encryptAndSaveData(data, forKey: key.rawValue)
    }

    func removeRemoteImage(forURL remoteURL: SafeRemoteURL) {
        let key = cacheKey(forURL: remoteURL)
        encryptedCache.removeData(forKey: key.rawValue)
    }

    func purge() {
        encryptedCache.purge()
    }

    private func cacheKey(forURL url: SafeRemoteURL) -> CacheKey {
        CacheKey(rawValue: url.value.sha512)
    }
}
