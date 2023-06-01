//
//  User.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation

class User {
    
    var email: String
    var password: String
    var mailboxPassword: String
    var twoFASecurityKey: String
    var name: String
    var pmMeEmail: String

    // quark
    var id: Int?
    var userPlan: UserPlan?
    var twoFARecoveryCodes: [String]?
    var numberOfImportedMails: Int?
    var quarkURL: URL?
    
    init(name: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.email = name + "@" + dynamicDomain!
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.name = name
        self.pmMeEmail = "\(name)@pm.me"
    }

    init(id: Int, name: String, email: String, password: String, userPlan: UserPlan, mailboxPassword: String, twoFASecurityKey: String, twoFARecoveryCodes: [String]?, numberOfImportedMails: Int?, quarkURL: URL) {
        self.id = id
        self.name = name
        self.email = email
        self.pmMeEmail = "\(name)@pm.me"
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
        self.email = String(userData[0])
        self.password = String(userData[1])
        self.mailboxPassword = String(userData[2])
        self.twoFASecurityKey = String(userData[3])
        self.name = String(String(userData[0]).split(separator: "@")[0])
        self.pmMeEmail = "\(name)@pm.me"
    }
    
    func getTwoFaCode() -> String {
        return Otp().generate(self.twoFASecurityKey)
    }
}
