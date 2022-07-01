//
//  AccountsAvailableForCreation.swift
//  ProtonCore-QuarkCommands - Created on 10.12.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import Foundation

public struct AccountAvailableForCreation {
    
    public enum AccountTypes {
        case free(status: AccountStatus? = nil)
        case subuser(ownerUserId: String, ownerUserPassword: String, alsoPublic: Bool, domain: String? = nil, status: SubuserAccountStatus? = nil)
        case plan(named: String, status: AccountStatus? = nil)
        
        var isNotPaid: Bool {
            guard case .plan = self else { return true }
            return false
        }
    }
    
    public enum KeyTypes: String {
        case none = "None"
        case rsa2048 = "RSA2048"
        case rsa4096 = "RSA4096"
        case curve25519 = "Curve25519"
    }
    
    public enum AddressTypes {
        case noAddress
        case addressButNoKeys
        case addressWithKeys(type: KeyTypes)
    }
    
    public enum AccountStatus: Int {
        case deleted = 0
        case disabled = 1
        case active = 2
        case vpnAdmin = 3
        case admin = 4
        case `super` = 5
    }
    
    public enum SubuserAccountStatus: Int {
        case deleted = 0
        case disabled = 1
        case active = 2
        case baseAdmin = 3
        case admin = 4
        case `super` = 5
        case abuser = 6
        case restricted = 7
        case bulkSender = 8
        case ransomware = 9
        case compromised = 10
        case bulkSignup = 11
        case bulkDisabled = 12
        case criminal = 13
        case chargeBack = 14
        case inactive = 15
        case forcePasswordChange = 16
        case selfDeleted = 17
        case csa = 18
        case spammer = 19
    }
    
    public enum AccountAuth: Int {
        case zero = 0
        case one = 1
        case two = 2
        case three = 3
        case four = 4
    }
    
    public let type: AccountTypes
    public let username: String
    public let password: String
    public let recoveryEmail: String?
    public let auth: AccountAuth?
    public let address: AddressTypes
    public let mailboxPassword: String?
    public let description: String
    
    public var statusValue: Int? {
        switch type {
        case .free(let status): return status?.rawValue
        case .subuser(_, _, _, _, let status): return status?.rawValue
        case .plan(_, let status): return status?.rawValue
        }
    }
    
    public init(type: AccountTypes = .free(),
                username: String,
                password: String,
                recoveryEmail: String? = nil,
                auth: AccountAuth? = nil,
                address: AddressTypes = .noAddress,
                mailboxPassword: String? = nil,
                description: String) {
        self.type = type
        self.username = username
        self.password = password
        self.recoveryEmail = recoveryEmail
        self.auth = auth
        self.address = address
        self.mailboxPassword = mailboxPassword
        self.description = description
    }
    
    public static func freeNoAddressNoKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(username: username ?? .random,
              password: password ?? .random,
              description: "Free account with no address nor keys")
    }
    
    public static func freeWithAddressButWithoutKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(username: username ?? .random,
              password: password ?? .random,
              address: .addressButNoKeys,
              description: "Free with address but without keys")
    }
    
    public static func freeWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Free with address and keys")
    }
    
    public static func freeWithAddressAndMailboxPassword(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              mailboxPassword: .random,
              description: "Free account with mailbox password")
    }
    
    public static func paid(
        plan: String, username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .plan(named: plan, status: .active),
              username: username ?? .random,
              password: password ?? .random,
              description: "Paid")
    }
    
    public static func deletedWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .free(status: .deleted),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Deleted account with address and keys")
    }
    
    public static func disabledWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .free(status: .disabled),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Disabled account with address and keys")
    }
    
    public static func vpnAdminWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .free(status: .vpnAdmin),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "VPN admin account with address and keys")
    }
    
    public static func adminWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .free(status: .admin),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Admin account with address and keys")
    }
    
    public static func superWithAddressAndKeys(
        username: String? = nil, password: String? = nil
    ) -> AccountAvailableForCreation {
        .init(type: .free(status: .super),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Super account with address and keys")
    }
    
    public static func subuserPublic(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: true),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser public account")
    }
    
    public static func subuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser private account")
    }
    
    public static func deletedSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .deleted),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser deleted private account")
    }
    public static func disabledSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .disabled),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser disabled private account")
    }
    public static func baseAdminSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .baseAdmin),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser baseAdmin private account")
    }
    public static func adminSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .admin),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser admin private account")
    }
    public static func superSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .super),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser super private account")
    }
    public static func abuserSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .abuser),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser abuser private account")
    }
    public static func restrictedSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .restricted),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser restricted private account")
    }
    public static func bulkSenderSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .bulkSender),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser bulkSender private account")
    }
    public static func ransomwareSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .ransomware),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser ransomware private account")
    }
    public static func compromisedSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .compromised),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser compromised private account")
    }
    public static func bulkSignupSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .bulkSignup),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser bulkSignup private account")
    }
    public static func bulkDisabledSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .bulkDisabled),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser bulkDisabled private account")
    }
    public static func criminalSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .criminal),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser criminal private account")
    }
    public static func chargeBackSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .chargeBack),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser chargeBack private account")
    }
    public static func inactiveSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .inactive),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser inactive private account")
    }
    public static func forcePasswordChangeSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .forcePasswordChange),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser forcePasswordChange private account")
    }
    public static func selfDeletedSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .selfDeleted),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser selfDeleted private account")
    }
    public static func csaSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .csa),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser csa private account")
    }
    public static func spammerSubuserPrivate(
        username: String? = nil, password: String? = nil, ownerUserId: String, ownerUserPassword: String
    ) -> AccountAvailableForCreation {
        .init(type: .subuser(ownerUserId: ownerUserId, ownerUserPassword: ownerUserPassword, alsoPublic: false, status: .spammer),
              username: username ?? .random,
              password: password ?? .random,
              address: .addressWithKeys(type: .curve25519),
              description: "Subuser spammer private account")
    }
}

extension String {
    static var random: String {
        var result: String = ""
        for _ in 1...Int.random(in: 8...20) {
            let randomCharacter: Character = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".randomElement() ?? "p"
            result.append(randomCharacter)
        }
        return result
    }
}
