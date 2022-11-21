//
//  Based64.swift
//  ProtonCore-Crypto - Created on 07/19/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

public enum Based64 {
    
    public static func encode(raw: Data) -> String {
        let base64Encoded = raw.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return base64Encoded
    }
    
    public static func encode(value: String) -> String {
        // this equals to value.data(using: String.Encoding.utf8). on swift 5.1 but it will every fail
        let utf8raw = Data(value.utf8)
        return self.encode(raw: utf8raw)
    }
    
    public static func decode(based64: String) -> Data {
        let decodedData = Data(base64Encoded: based64, options: NSData.Base64DecodingOptions(rawValue: 0))
        return decodedData!
    }
}
