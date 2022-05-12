//
//  Key+Fixtures.swift
//  ProtonCore-TestingToolkit - Created on 28.05.2021.
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

import ProtonCore_DataModel

public extension Key {

    static var dummy: Key {
        Key(keyID: .empty,
            privateKey: nil,
            keyFlags: .zero,
            token: nil,
            signature: nil,
            activation: nil,
            active: .zero,
            version: .zero,
            primary: .zero,
            isUpdated: false)
    }

    func updated(keyID: String? = nil,
                 privateKey: String? = nil,
                 keyFlags: Int? = nil,
                 token: String? = nil,
                 signature: String? = nil,
                 activation: String? = nil,
                 active: Int? = nil,
                 version: Int? = nil,
                 primary: Int? = nil,
                 isUpdated: Bool? = nil) -> Key {
        Key(keyID: keyID ?? self.keyID,
            privateKey: privateKey ?? self.privateKey,
            keyFlags: keyFlags ?? self.keyFlags,
            token: token ?? self.token,
            signature: signature ?? self.signature,
            activation: activation ?? self.activation,
            active: active ?? self.active,
            version: version ?? self.version,
            primary: primary ?? self.primary,
            isUpdated: isUpdated ?? self.isUpdated)
    }

}
