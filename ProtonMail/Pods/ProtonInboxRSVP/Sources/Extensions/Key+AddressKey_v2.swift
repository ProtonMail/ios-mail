// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import ProtonCoreDataModel

extension Key {

    convenience init(codable key: AddressKey_v2) {
        self.init(
            keyID: key.id,
            privateKey: key.privateKey,
            keyFlags: Int(key.flags.rawValue),
            token: key.token,
            signature: key.signature,
            activation: nil,
            active: key.active.intValue,
            version: key.version,
            primary: key.primary.intValue,
            isUpdated: false
        )
    }

}
