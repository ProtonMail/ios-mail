//
//  User.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation

struct UserSettings: Decodable {
    let plans: String?
    let flags: Flags

    enum CodingKeys: String, CodingKey {
        case plans = "Plans"
        case flags = "Flags"
    }
}

struct Flags: Decodable {
    let welcomed: String

    enum CodingKeys: String, CodingKey {
        case welcomed = "Welcomed"
    }
}

struct TestUser: Decodable {
    let user: User
    let userSettings: UserSettings?

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case userSettings = "UserSettings"
    }
}

struct User: Decodable {
    var name: String
    var displayName: String
    var password: String

    var email: String {
        return "\(name)@\(dynamicDomain)"
    }
    var pmMeEmail: String {
        return "\(name)@pm.me"
    }

    // additional properties...
    var mailboxPassword: String
    var twoFASecurityKey: String
    var id: Int?
    var userPlan: UserPlan?
    var twoFARecoveryCodes: [String]?
    var numberOfImportedMails: Int?
    var quarkURL: URL?

    enum CodingKeys: String, CodingKey {
        case name = "Username"
        case displayName = "DisplayName"
        case password = "Password"
        // add more coding keys as per your properties...
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.password = try container.decode(String.self, forKey: .password)
        self.mailboxPassword = ""
        self.twoFASecurityKey = ""
    }

    init() {
        self.name = StringUtils().randomAlphanumericString(length: 8)
        self.password = StringUtils().randomAlphanumericString(length: 8)
        self.displayName = name
        self.mailboxPassword = ""
        self.twoFASecurityKey = ""
    }

    init(name: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.name = name
        self.displayName = name
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.name = name
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
