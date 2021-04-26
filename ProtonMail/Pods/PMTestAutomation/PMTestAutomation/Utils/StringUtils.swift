//
//  StringUtils.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 09.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

public struct StringUtils {

    public static func randomEmailString(length: Int = 5) -> String {
        let allowedChars = "abcdefghijklmnopqrstuuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!#$%&*+-=?^`{|}~"
        let allowedCharsCount = UInt32(allowedChars.count)
        var randomString = randomAlphanumericString(length: 1) /// needed to avoid special char at the first place

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }
        return randomString
    }

    public static func randomAlphanumericString(length: Int = 10) -> String {
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

    /**
     Formats UI element action callers, so caller info can be added later to a failure description if test fails.
     Example: ↪︎LoginRobot.username()
     */
    func formatCallers(_ stacktrace: (String, String)) -> String {
        return "↪︎\(stacktrace.0).\(stacktrace.1)()\n"
    }
}

extension String {

    func replaceSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "_")
    }
}
