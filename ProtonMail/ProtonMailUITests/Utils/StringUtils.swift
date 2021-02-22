//
//  StringUtils.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 09.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

struct StringUtils {
    
    func randomEmail(length: Int = 5) -> String {
        let allowedChars = "abcdefghijklmnopqrstuuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!#$%&*+-=?^`{|}~"
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
    
    func randomAlphanumericString(length: Int = 10) -> String {
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
}

extension String {
    
    func replaceSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "_")
    }
}
