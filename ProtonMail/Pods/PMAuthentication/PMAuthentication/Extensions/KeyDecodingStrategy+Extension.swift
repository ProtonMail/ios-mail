//
//  KeyDecodingStrategy.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension JSONDecoder.KeyDecodingStrategy {
    /// Lowercases first character if the key does not start with acronym or adds underscore if first character is a digit.
    /// Example: UserID → userID, SPRSession → SRPSessoin, 2fa → _2fa
    static var decapitaliseFirstLetter: JSONDecoder.KeyDecodingStrategy {
        .custom { keys in
            let lastKey = keys.last!
            if lastKey.intValue != nil {
                return lastKey
            }
            
            // let's hope server will not return unicode glyphs as JSON keys
            let originalKey: String = lastKey.stringValue
            if CharacterSet.decimalDigits.contains(originalKey.unicodeScalars.first!) {
                // we will just add _ in the beginning if first character is a digit (like 2FA)
                return BasicCodingKey(stringValue: "_" + originalKey)!
            }
            
            let prefix = originalKey.prefix(while: { $0.unicodeScalars.first(where: { CharacterSet.uppercaseLetters.contains($0) }) != nil })
            
            if prefix.count == 1 {
                // we will transform only keys starting with one uppercase letter (like Code or UserID)
                let modifiedKey = String(prefix).lowercased() + originalKey.dropFirst(prefix.count)
                return BasicCodingKey(stringValue: modifiedKey)!
            } else {
                // we do not want to transform keys that start with acronyms (like UID or SRPSession)
                return BasicCodingKey(stringValue: originalKey)!
            }
        }
    }
}

/// String value becomes the key
struct BasicCodingKey: CodingKey {
  var stringValue: String
  init?(stringValue: String) {
    self.stringValue = stringValue
  }

  var intValue: Int? {
    return nil
  }
  init?(intValue: Int) {
    return nil
  }
}
