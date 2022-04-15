// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_Crypto
import ProtonCore_DataModel

struct UserDataServiceKeyHelper {
    struct UpdatedKeyResult {
        let saltOfNewPassword: Data
        let hashedNewPassword: String
        let updatedUserKeys: [Key]
        let originalUserKeys: [Key]
        let updatedAddresses: [Address]?
    }

    func updatePasswordV2(userKeys: [Key], oldPassword: String, newPassword: String) throws -> UpdatedKeyResult {
        let saltOfNewPassword = try Crypto.random(byte: 16) // mailbox pwd need 128 bits
        let hashedNewPassword = PasswordUtils.getMailboxPassword(newPassword, salt: saltOfNewPassword)
        let result = try Crypto.updateKeysPassword(userKeys, old_pass: oldPassword, new_pass: hashedNewPassword)
        let updatedKeys = result.filter({ $0.isUpdated == true })
        let originalKeys = result.filter({ $0.isUpdated == false })
        return UpdatedKeyResult(saltOfNewPassword: saltOfNewPassword,
                                hashedNewPassword: hashedNewPassword,
                                updatedUserKeys: updatedKeys,
                                originalUserKeys: originalKeys,
                                updatedAddresses: nil)
    }

    func updatePassword(userKeys: [Key], addressKeys: [Address], oldPassword: String, newPassword: String) throws -> UpdatedKeyResult {
        let saltOfNewPassword = try Crypto.random(byte: 16) // mailbox pwd need 128 bits
        let hashedNewPassword = PasswordUtils.getMailboxPassword(newPassword, salt: saltOfNewPassword)
        let userKeyResult = try Crypto.updateKeysPassword(userKeys, old_pass: oldPassword, new_pass: hashedNewPassword)
        let updatedUserKeys = userKeyResult.filter({ $0.isUpdated == true })
        let originalUserKeys = userKeyResult.filter({ $0.isUpdated == false })

        let addressKeyResult = try
        Crypto.updateAddrKeysPassword(addressKeys, old_pass: oldPassword, new_pass: hashedNewPassword)

        return UpdatedKeyResult(saltOfNewPassword: saltOfNewPassword,
                                hashedNewPassword: hashedNewPassword,
                                updatedUserKeys: updatedUserKeys,
                                originalUserKeys: originalUserKeys,
                                updatedAddresses: addressKeyResult)
    }
}
