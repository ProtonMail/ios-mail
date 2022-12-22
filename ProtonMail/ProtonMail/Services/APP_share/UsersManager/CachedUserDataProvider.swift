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

import Foundation
import ProtonCore_Keymaker

// sourcery: mock
protocol CachedUserDataProvider {
    func set(disconnectedUsers: [UsersManager.DisconnectedUserHandle])
    func fetchDisconnectedUsers() -> [UsersManager.DisconnectedUserHandle]
}

class UserDataCache: CachedUserDataProvider {
    enum Constant {
        static let disconnectedUsers = "disconnectedUsers"
    }

    private let keyMaker: Keymaker
    private let keychain: KeychainWrapper

    init(
        keyMaker: Keymaker = keymaker,
        keychain: KeychainWrapper = KeychainWrapper.keychain
    ) {
        self.keyMaker = keyMaker
        self.keychain = keychain
    }

    func set(disconnectedUsers: [UsersManager.DisconnectedUserHandle]) {
        guard let mainKey = keyMaker.mainKey(by: RandomPinProtection.randomPin),
              let data = try? JSONEncoder().encode(disconnectedUsers),
              let locked = try? Locked(clearValue: data, with: mainKey) else {
            return
        }
        keychain.set(locked.encryptedValue, forKey: Constant.disconnectedUsers)
    }

    func fetchDisconnectedUsers() -> [UsersManager.DisconnectedUserHandle] {
        guard let mainKey = keyMaker.mainKey(by: RandomPinProtection.randomPin),
              let encryptedData = keychain.data(forKey: Constant.disconnectedUsers),
              case let locked = Locked<Data>(encryptedValue: encryptedData),
              let data = try? locked.unlock(with: mainKey),
              let loggedOutUserHandles = try? JSONDecoder().decode(
                [UsersManager.DisconnectedUserHandle].self,
                from: data
              )
        else {
            return []
        }
        return loggedOutUserHandles
    }
}
