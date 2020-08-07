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
}
