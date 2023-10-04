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

// sourcery: mock
protocol PushDecryptionKeysProvider {
    var pushNotificationsDecryptionKeys: [DecryptionKey] { get }
}

extension PushEncryptionKitSaver: PushDecryptionKeysProvider {

    var pushNotificationsDecryptionKeys: [DecryptionKey] {
        let kits: [EncryptionKit]? = saver.get()
        guard let kits, !kits.isEmpty else {
            SystemLogger.log(message: "no push decryption keys found in cache", category: .encryption)
            return []
        }
        return kits.map(\.decryptionKey)
    }
}

private extension EncryptionKit {

    var decryptionKey: DecryptionKey {
        DecryptionKey(
            privateKey: ArmoredKey(value: privateKey),
            passphrase: Passphrase(value: passphrase)
        )
    }
}
