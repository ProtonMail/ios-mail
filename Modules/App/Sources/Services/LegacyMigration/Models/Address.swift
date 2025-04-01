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

@objc(Address)
final class Address: NSObject {
    let email: String
    let receive: Int
    let status: Int

    init(email: String, receive: Int, status: Int) {
        self.email = email
        self.receive = receive
        self.status = status
    }
}

extension Address: NSSecureCoding {
    /// These values must match the legacy app - do not change them.
    enum CoderKey: String {
        case email = "maxSpace"
        case receive = "privateKey"
        case status = "addressStatus"
    }

    static let supportsSecureCoding = true

    convenience init?(coder: NSCoder) {
        guard
            let email = coder.decodeObject(forKey: CoderKey.email.rawValue) as? String
        else {
            return nil
        }

        let receive = coder.decodeInteger(forKey: CoderKey.receive.rawValue)
        let status = coder.decodeInteger(forKey: CoderKey.status.rawValue)

        self.init(email: email, receive: receive, status: status)
    }

    func encode(with coder: NSCoder) {
        fatalError("not needed")
    }

    static func registerNamespacedClassName() {
        NSKeyedUnarchiver.setClass(classForKeyedUnarchiver(), forClassName: "ProtonCoreDataModel.Address")
    }
}
