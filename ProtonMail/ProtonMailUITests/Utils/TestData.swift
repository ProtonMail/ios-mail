//
//  TestUser.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

class TestData {
    
    var onePassUser = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var twoPassUser = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var onePassUserWith2Fa = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var twoPassUserWith2Fa = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    
    var internalEmailTrustedKeys = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var internalEmailNotTrustedKeys = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var externalEmailPGPEncrypted = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
    var externalEmailPGPSigned = User(email: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", twoFASecurityKey: "twoFAStub")
        
    var messageSubject: String { return "Random Subject \(Date().millisecondsSince1970)" }
    var newMessageSubject: String { return "New Random Subject \(Date().millisecondsSince1970)" }
    var messageBody: String { return "Hello ProtonMail!Random body: \(Date().millisecondsSince1970)" }
    
    var alphaNumericString: String { return "_\(StringUtils().randomAlphanumericString())\(Date().millisecondsSince1970)" }
    var newEmailAddress: String { return "\(StringUtils().randomEmail())@pm.me" }
    
    let editedPassword = "P@ssw0rd!"
    let editedPasswordHint = "ProtonMail"
}
