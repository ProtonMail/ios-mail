//
//  TestUser.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation
import ProtonCoreQuarkCommands

class TestData {
    
    var onePassUser = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var twoPassUser = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var onePassUserWith2Fa = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var twoPassUserWith2Fa = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    
    var internalEmailTrustedKeys = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var internalEmailNotTrustedKeys = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var externalEmailPGPEncrypted = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
    var externalEmailPGPSigned = User(name: "emailStub", password: "pwdStub", mailboxPassword: "mailPwdStub", totpSecurityKey: "twoFAStub")
        
    var messageSubject: String { return "\(Date().millisecondsSince1970)" }
    var newMessageSubject: String { return "New \(Date().millisecondsSince1970)" }
    var messageBody: String { return "Body: \(Date().millisecondsSince1970)" }
    
    var alphaNumericString: String { return "_\(StringUtils().randomAlphanumericString())\(Date().millisecondsSince1970)" }
    var alphaNumericStringStartingFromX: String { return "x_\(StringUtils().randomAlphanumericString())\(Date().millisecondsSince1970)" }
    var newEmailAddress: String { return "\(StringUtils().randomEmail())@pm.me" }
    
    let editedPassword = "P@ssw0rd!"
    let editedPasswordHint = "ProtonMail"
}
