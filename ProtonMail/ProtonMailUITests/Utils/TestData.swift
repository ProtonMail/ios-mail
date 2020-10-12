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
        
    var messageSubject: String { return "Random Subject: \(Date().millisecondsSince1970)" }
    var messageBody: String { return "Hello ProtonMail!Random body: \(Date().millisecondsSince1970)" }
    
    var alphaNumericString: String { return "_\(randomAlphanumericString())\(Date().millisecondsSince1970)" }
    var newEmailAddress: String { return "\(randomEmail())@pm.me" }
    
    let editedPassword = "P@ssw0rd!"
    let editedPasswordHint = "ProtonMail"
    
    private func randomAlphanumericString(length: Int = 10) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        let allowedCharsCount = UInt32(allowedChars.count)
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
    
    private func randomEmail(length: Int = 5) -> String {
        let allowedChars = "abcdefghijklmnopqrstuuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!#$%&'*+-=?^`{|}~"
        let allowedCharsCount = UInt32(allowedChars.count)
        var randomString = "a" /// needed to avoid special char in the first place

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
}

extension Date {
 var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
