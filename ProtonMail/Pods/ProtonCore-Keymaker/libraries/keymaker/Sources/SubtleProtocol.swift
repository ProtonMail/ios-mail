//
//  SubtleProtocol.swift
//  ProtonCore-Keymaker - Created on 12/03/2020.
//
//  Copyright (c) 2020 Proton Technologies AG
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

public protocol SubtleProtocol {
    static func DeriveKey(_ one: String, _ salt: Data, _ three: Int, _ four: inout NSError?) -> Data?
    static func EncryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data?
    static func DecryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data?
    static func Random(_ bitlen: Int) -> Data?
}
