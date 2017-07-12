//
//  NSDataExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/10/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

extension Data {
    
    
    public func stringFromToken() -> String {
        let tokenChars = (self as NSData).bytes.bindMemory(to: CChar.self, capacity: self.count)
        var tokenString = ""
        for i in 0 ..< self.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        return tokenString
    }
    
    
    
    public func encodeBase64() -> String {
        return self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
