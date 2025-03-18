// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import InboxKeychain

final class LegacyKeychain: Keychain {
    enum Key: String {
        case unprotectedMainKey = "NoneProtection"
    }

    init() {
        // TODO: use the intended legacy accessGroup once we change the bundle identifier
//        super.init(service: "ch.protonmail", accessGroup: "2SB5Z68H26.ch.protonmail.protonmail")
        super.init(service: "ch.protonmail", accessGroup: "group.me.proton.mail")
    }

    func data(forKey key: Key) throws -> Data? {
        try dataOrError(forKey: key.rawValue)
    }
}
