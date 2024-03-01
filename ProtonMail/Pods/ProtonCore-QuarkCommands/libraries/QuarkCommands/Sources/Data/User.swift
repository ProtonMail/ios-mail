//
//  User.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
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

public struct Settings: Decodable {
    let flags: Flags?

    enum CodingKeys: String, CodingKey {
        case flags = "Flags"
    }
}

public struct Flags: Decodable {
    let welcomed: String

    enum CodingKeys: String, CodingKey {
        case welcomed = "Welcomed"
    }
}

public struct SubscriptionHistory: Decodable {
    let subscriptionHistory: String

    enum CodingKeys: String, CodingKey {
        case subscriptionHistory = "SubscriptionHistory"
    }
}

public struct User: Decodable {
    public var name: String
    public var password: String
    public var settings: Settings?
    public var subscriptionHistory: String? = ""

    public var email: String

    public var pmMeEmail: String {
        return "\(name)@pm.me"
    }

    // additional properties...
    public var mailboxPassword: String
    public var twoFASecurityKey: String
    public var displayName: String
    public var id: Int?
    public var userPlan: UserPlan?
    public var twoFARecoveryCodes: [String]?
    public var numberOfImportedMails: Int?
    public var quarkURL: URL?
    public var isExternal: Bool = false
    public var passphrase: String = ""
    public var recoveryEmail: String = ""

    public enum CodingKeys: String, CodingKey {
        case name = "UserName"
        case password = "Password"
        case settings = "Settings"
        case subscriptionHistory = "SubscriptionHistory"
        // add more coding keys as per your properties...
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.password = try container.decode(String.self, forKey: .password)
        self.mailboxPassword = ""
        self.twoFASecurityKey = ""
        self.displayName = name
        self.email = name
    }

    public init(name: String, password: String, mailboxPassword: String = "", twoFASecurityKey: String = "") {
        self.name = name
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.displayName = name
        self.email = name
    }

    public init(email: String, name: String, password: String, isExternal: Bool = false) {
        self.name = name
        self.password = password
        self.email = email
        self.displayName = name
        self.isExternal = isExternal
        self.mailboxPassword = ""
        self.twoFASecurityKey = ""
    }

    init(user: String) {
        let userData = user.split(separator: ",")
        self.name = String(userData[0].split(separator: "@")[0])
        self.password = String(userData[1])
        self.mailboxPassword = userData.count > 2 ? String(userData[2]) : ""
        self.twoFASecurityKey = userData.count > 3 ? String(userData[3]) : ""
        self.displayName = name
        self.email = name
    }
}
