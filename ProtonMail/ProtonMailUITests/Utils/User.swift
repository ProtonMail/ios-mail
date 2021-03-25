//
//  User.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

class User {
    
    var email: String
    var password: String
    var mailboxPassword: String
    var twoFASecurityKey: String
    var name: String
    var pmMeEmail: String
    
    init(email: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.email = email
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.name = String(email.split(separator: "@")[0])
        self.pmMeEmail = "\(name)@pm.me"
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
