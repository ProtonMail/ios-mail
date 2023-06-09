//
//  User.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation

struct Settings: Decodable {
    let flags: Flags?

    enum CodingKeys: String, CodingKey {
        case flags = "Flags"
    }
}

struct Flags: Decodable {
    let welcomed: String

    enum CodingKeys: String, CodingKey {
        case welcomed = "Welcomed"
    }
}

struct SubscriptionHistory: Decodable {
    let subscriptionHistory: String

    enum CodingKeys: String, CodingKey {
        case subscriptionHistory = "SubscriptionHistory"
    }
}

struct User: Decodable {
    var name: String
    var password: String
    var settings: Settings? = nil
    var subscriptionHistory: String? = ""

    var email: String {
        return "\(name)@\(dynamicDomain)"
    }
    var pmMeEmail: String {
        return "\(name)@pm.me"
    }

    // additional properties...
    var mailboxPassword: String
    var twoFASecurityKey: String
    var displayName: String
    var id: Int?
    var userPlan: UserPlan?
    var twoFARecoveryCodes: [String]?
    var numberOfImportedMails: Int?
    var quarkURL: URL?

    enum CodingKeys: String, CodingKey {
        case name = "UserName"
        case password = "Password"
        case settings = "Settings"
        case subscriptionHistory = "SubscriptionHistory"
        // add more coding keys as per your properties...
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.password = try container.decode(String.self, forKey: .password)
        self.mailboxPassword = ""
        self.twoFASecurityKey = ""
        self.displayName = name
    }

    init() {
        self.name = StringUtils().randomAlphanumericString(length: 8)
        self.password = StringUtils().randomAlphanumericString(length: 8)
        self.mailboxPassword = ""
        self.displayName = name
        self.twoFASecurityKey = ""
    }

    init(name: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.name = name
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.name = name
        self.displayName = name
    }

    init(id: Int, name: String, email: String, password: String, userPlan: UserPlan, mailboxPassword: String, twoFASecurityKey: String, twoFARecoveryCodes: [String]?, numberOfImportedMails: Int?, quarkURL: URL) {
        self.id = id
        self.name = name
        self.displayName = name
        self.password = password
        self.userPlan = userPlan
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.twoFARecoveryCodes = twoFARecoveryCodes
        self.numberOfImportedMails = numberOfImportedMails
        self.quarkURL = quarkURL
    }

    init(user: String) {
        let userData = user.split(separator: ",")
        self.password = String(userData[1])
        self.mailboxPassword = String(userData[2])
        self.twoFASecurityKey = String(userData[3])
        self.name = String(String(userData[0]).split(separator: "@")[0])
        self.displayName = name
    }

    func getTwoFaCode() -> String {
        return Otp().generate(self.twoFASecurityKey)
    }
}
