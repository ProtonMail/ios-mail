//
//  NSDataExtension.swift
//  Proton Mail - Created on 2/10/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Data {

    /// Converts binary data to hexadecimal representation
    func stringFromToken() -> String {
        let tokenChars = (self as NSData).bytes.bindMemory(to: CChar.self, capacity: self.count)
        var tokenString = ""
        for idx in 0 ..< self.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[idx]])
        }
        return tokenString
    }
}
