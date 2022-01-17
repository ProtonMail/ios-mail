//
//  NSDataExtension.swift
//  ProtonMail - Created on 2/10/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Data {

    func stringFromToken() -> String {
        let tokenChars = (self as NSData).bytes.bindMemory(to: CChar.self, capacity: self.count)
        var tokenString = ""
        for i in 0 ..< self.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        return tokenString
    }

    func encodeBase64() -> String {
        return self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
