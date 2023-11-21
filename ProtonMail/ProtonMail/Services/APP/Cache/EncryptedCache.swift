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

import ProtonCoreKeymaker
import SDWebImage

class EncryptedCache {
    typealias Dependencies = AnyObject & HasKeychain & HasKeyMakerProtocol

    private unowned let dependencies: Dependencies
    private let internalCache: SDDiskCache

    init(internalCache: SDDiskCache, dependencies: Dependencies) {
        self.dependencies = dependencies
        self.internalCache = internalCache
    }

    convenience init(maxDiskSize: UInt, subdirectory: String, dependencies: Dependencies) {
        let config = SDImageCacheConfig()
        config.maxDiskAge = -1
        config.maxDiskSize = maxDiskSize

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(subdirectory, isDirectory: true)

        guard let internalCache = SDDiskCache(cachePath: cacheDir.path, config: config) else {
            fatalError("Cannot initialize SDDiskCache")
        }

        self.init(internalCache: internalCache, dependencies: dependencies)
    }

    func purge() {
        internalCache.removeAllData()
    }

    func decryptedData(forKey key: String) throws -> Data? {
        let mainKey = try prepareMainKey()

        guard let ciphertext = internalCache.data(forKey: key) else {
            return nil
        }

        let locked = Locked<Data>(encryptedValue: ciphertext)
        let plaintext = try locked.unlock(with: mainKey)
        return plaintext
    }

    func encryptAndSaveData(_ plaintext: Data, forKey key: String) throws {
        let mainKey = try prepareMainKey()
        let locked = try Locked<Data>(clearValue: plaintext, with: mainKey)
        let ciphertext = locked.encryptedValue
        internalCache.setData(ciphertext, forKey: key)
    }

    func removeData(forKey key: String) {
        internalCache.removeData(forKey: key)
    }

    private func prepareMainKey() throws -> MainKey {
        guard let mainKey = dependencies.keyMaker.mainKey(by: dependencies.keychain.randomPinProtection) else {
            throw EncryptedCacheError.cannotObtainMainKey
        }

        return mainKey
    }
}
