//
//  Encoded.swift
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

public enum EncodedType {
    public enum Based64 {}
    public enum Hex {}
}

public struct Encoded<Type> {
    public let value: String
    
    public init(based64: String) {
        self.value = based64
    }
}

public typealias Based64String = Encoded<EncodedType.Based64>

extension Encoded where Type == EncodedType.Based64 {
    public init(raw: Data) {
        self.value = Based64.encode(raw: raw)
    }
    
    public var decode: Data {
        return Based64.decode(based64: value)
    }
}
