//
//  PasswordChangeServiceKeyHelper.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import ProtonCoreAuthenticationKeyGeneration
import ProtonCoreCrypto
import ProtonCoreDataModel

struct PasswordChangeServiceKeyHelper {
    struct UpdatedKeyResult {
        let saltOfNewPassword: Data
        let hashedNewPassword: Passphrase
        let updatedUserKeys: [Key]
        let originalUserKeys: [Key]
        let updatedAddresses: [Address]?
    }

    func updatePasswordV2(userKeys: [Key], oldPassword: Passphrase, newPassword: Passphrase) throws -> UpdatedKeyResult {
        guard let saltOfNewPassword = try SrpRandomBits(PasswordSaltSize.accountKey.IntBits) else {
            throw UpdatePasswordError.cantHashPassword
        }
        let hashedNewPassword = PasswordHash.hashPassword(newPassword.value, salt: saltOfNewPassword)
        let result = try Crypto.updateKeysPassword(userKeys, oldPass: oldPassword, newPass: .init(value: hashedNewPassword))
        let updatedKeys = result.filter({ $0.isUpdated == true })
        let originalKeys = result.filter({ $0.isUpdated == false })
        return UpdatedKeyResult(
            saltOfNewPassword: saltOfNewPassword,
            hashedNewPassword: .init(value: hashedNewPassword),
            updatedUserKeys: updatedKeys,
            originalUserKeys: originalKeys,
            updatedAddresses: nil
        )
    }

    func updatePassword(userKeys: [Key], addressKeys: [Address], oldPassword: Passphrase, newPassword: Passphrase) throws -> UpdatedKeyResult {
        guard let saltOfNewPassword = try SrpRandomBits(PasswordSaltSize.accountKey.IntBits) else {
            throw UpdatePasswordError.cantHashPassword
        }
        let hashedNewPassword = PasswordHash.hashPassword(newPassword.value, salt: saltOfNewPassword)
        let userKeyResult = try Crypto.updateKeysPassword(userKeys, oldPass: oldPassword, newPass: .init(value: hashedNewPassword))
        let updatedUserKeys = userKeyResult.filter({ $0.isUpdated == true })
        let originalUserKeys = userKeyResult.filter({ $0.isUpdated == false })

        let addressKeyResult = try
        Crypto.updateAddrKeysPassword(
            addressKeys,
            oldPass: oldPassword,
            newPass: .init(value: hashedNewPassword)
        )

        return UpdatedKeyResult(
            saltOfNewPassword: saltOfNewPassword,
            hashedNewPassword: .init(value: hashedNewPassword),
            updatedUserKeys: updatedUserKeys,
            originalUserKeys: originalUserKeys,
            updatedAddresses: addressKeyResult
        )
    }
}

#endif
