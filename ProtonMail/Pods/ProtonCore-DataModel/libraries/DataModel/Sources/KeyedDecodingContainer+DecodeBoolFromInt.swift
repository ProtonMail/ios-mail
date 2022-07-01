//
//  KeyedDecodingContainer+DecodeBoolFromInt.swift
//  ProtonCore-DataModel - Created on 26.04.22.
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

extension KeyedDecodingContainer {
    
    /// Decodes a boolean from an integer for the given key.
    ///
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A boolean, if present for the given key and convertible to the requested type.
    /// - throws: `DecodingError.dataCorrupted` if the encountered encoded value
    ///   is different than 0 or 1.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the Integer type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    public func decodeBoolFromInt(forKey key: KeyedDecodingContainer<K>.Key) throws -> Bool {
        let integer = try decode(Int.self, forKey: key)
        let boolValue: Bool
        switch integer {
        case 0:
            boolValue = false
        case 1:
            boolValue = true
        default:
            let errorDescription = "Expected to receive `0` or `1` but found `\(integer)` instead."
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: errorDescription)
        }
        
        return boolValue
    }
    
}
