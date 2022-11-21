//
//  Crypto+Data.swift
//  ProtonCore-Crypto - Created on 9/11/19.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import GoLibs

extension Data { // need follow the gomobile fixes
    /// This computed value is only needed because of [this](https://github.com/golang/go/issues/33745) issue in the
    /// golang/go repository. It is a workaround until the problem is solved upstream.
    ///
    /// The data object is converted into an array of bytes and than returned wrapped in an `NSMutableData` object. In
    /// thas way Gomobile takes it as it is without copying. The Swift side remains responsible for garbage collection.
    var mutable: NSMutableData {
        var array = [UInt8](self)
        return NSMutableData(bytes: &array, length: count)
    }
}

extension Data {
    // self is public key
    public func isExpired() -> Bool {
        do {
            let key = try throwingNotNil { error in CryptoNewKey(self, &error) }
            return key.isExpired()
        } catch {
            return false
        }
    }
}
