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

@objc(UserInfo)
final class UserInfo: NSObject {
    let displayName: String
    let passwordMode: Int
    let userAddresses: [Address]
    let userId: String

    init(displayName: String, passwordMode: Int, userAddresses: [Address], userId: String) {
        self.displayName = displayName
        self.passwordMode = passwordMode
        self.userAddresses = userAddresses
        self.userId = userId
    }
}

extension UserInfo: NSSecureCoding {
    enum CoderKey: String {
        case displayName
        case passwordMode
        case userAddresses
        case userId
    }

    static let supportsSecureCoding = true

    convenience init?(coder: NSCoder) {
        guard
            let displayName = coder.decodeObject(forKey: CoderKey.displayName.rawValue) as? String,
            let userAddresses = coder.decodeObject(forKey: CoderKey.userAddresses.rawValue) as? [Address],
            let userId = coder.decodeObject(forKey: CoderKey.userId.rawValue) as? String
        else {
            return nil
        }

        let passwordMode = coder.decodeInteger(forKey: CoderKey.passwordMode.rawValue)

        self.init(displayName: displayName, passwordMode: passwordMode, userAddresses: userAddresses, userId: userId)
    }

    func encode(with coder: NSCoder) {
        fatalError("not needed")
    }
}
