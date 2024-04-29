// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import ProtonCoreCrypto
import ProtonCoreDataModel

public enum AddressKeyPacketReEncryptor {

    public static func reEncryptedKeyPacket(
        addressKeyPacket: String,
        withCalendarKey activePrimaryCalendarKey: CalendarKey,
        decryptionPackage: AddressKeyPackage
    ) throws -> String {
        let decryptedSessionKeyWithAddressKey = try decryptedSessionKey(
            fromAddressKeyPacket: addressKeyPacket,
            decryptionPackage: decryptionPackage
        )
        let encryptedSessionKeyWithCalendarKey: Based64String = try Encryptor.encryptSession(
            publicKey: .init(value: activePrimaryCalendarKey.privateKey.publicKey),
            sessionKey: decryptedSessionKeyWithAddressKey
        )

        return encryptedSessionKeyWithCalendarKey.value
    }

    private static func decryptedSessionKey(
        fromAddressKeyPacket addressKeyPacket: String,
        decryptionPackage: AddressKeyPackage
    ) throws -> SessionKey {
        let addressDecryptionKeys = try decryptionPackage.decryptionKeys()
        let decryptedSessionKey: SessionKey = try Decryptor.decryptSessionKey(
            decryptionKeys: addressDecryptionKeys,
            keyPacket: addressKeyPacket.decodeBase64()
        )

        return decryptedSessionKey
    }

}
