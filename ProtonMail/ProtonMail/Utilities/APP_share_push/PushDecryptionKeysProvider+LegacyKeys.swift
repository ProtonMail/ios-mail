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

extension PushDecryptionKeysProvider {

    /// Returns the keys stored using the new implementation `PushEncryptionManager` appending
    /// any key existing in the old saver implementation.
    func decryptionKeysAppendingLegacyKey(
        from saver: Saver<Set<PushSubscriptionSettings>>,
        forUID uid: String
    ) -> [DecryptionKey] {
        var decryptionKeys = pushNotificationsDecryptionKeys
        if let oldDecryptionKey = oldDecryptionKeys(saver: saver, forUID: uid) {
            decryptionKeys.append(oldDecryptionKey)
        }
        return decryptionKeys
    }

    /// Returns a key that might have been stored before `PushDecryptionKeysProvider`
    private func oldDecryptionKeys(saver: Saver<Set<PushSubscriptionSettings>>, forUID uid: String) -> DecryptionKey? {
        guard let kit = saver.get()?.first(where: { $0.UID == uid })?.encryptionKit else {
            return nil
        }
        return DecryptionKey(
            privateKey: ArmoredKey(value: kit.privateKey),
            passphrase: Passphrase(value: kit.passphrase)
        )
    }
}
