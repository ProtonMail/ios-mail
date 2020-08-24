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
    
    init(email: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.email = email
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
    }
    
    init(user: String) {
        let userData = user.split(separator: ",")
        self.email = String(userData[0])
        self.password = String(userData[1])
        self.mailboxPassword = String(userData[2])
        self.twoFASecurityKey = String(userData[3])
    }
    
    func getTwoFaCode() -> String {
        return Otp().generate(self.twoFASecurityKey)
    }
}
