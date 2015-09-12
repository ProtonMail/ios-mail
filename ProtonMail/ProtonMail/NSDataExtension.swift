//
//  NSDataExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/10/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

extension NSData {
    
    
    public func stringFromToken() -> String {
        let tokenChars = UnsafePointer<CChar>(self.bytes)
        var tokenString = ""
        for i in 0 ..< self.length {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        return tokenString
    }
}