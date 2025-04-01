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

@objc(AuthCredential)
final class AuthCredential: NSObject {
    let mailboxPassword: String
    let refreshToken: String
    let sessionID: String
    let userID: String
    let userName: String

    init(
        mailboxPassword: String,
        refreshToken: String,
        sessionID: String,
        userID: String,
        userName: String
    ) {
        self.mailboxPassword = mailboxPassword
        self.refreshToken = refreshToken
        self.sessionID = sessionID
        self.userID = userID
        self.userName = userName
    }
}

extension AuthCredential: NSSecureCoding {
    /// These values must match the legacy app - do not change them.
    enum CoderKey: String {
        case mailboxPassword = "AuthCredential.Password"
        case refreshToken = "refreshTokenCoderKey"
        case sessionID = "userIDCoderKey"
        case userID = "AuthCredential.UserID"
        case userName = "AuthCredential.UserName"
    }

    static let supportsSecureCoding = true

    convenience init?(coder: NSCoder) {
        guard
            let mailboxPassword = coder.decodeObject(forKey: CoderKey.mailboxPassword.rawValue) as? String,
            let refreshToken = coder.decodeObject(forKey: CoderKey.refreshToken.rawValue) as? String,
            let sessionID = coder.decodeObject(forKey: CoderKey.sessionID.rawValue) as? String,
            let userID = coder.decodeObject(forKey: CoderKey.userID.rawValue) as? String,
            let userName = coder.decodeObject(forKey: CoderKey.userName.rawValue) as? String
        else {
            return nil
        }

        self.init(
            mailboxPassword: mailboxPassword,
            refreshToken: refreshToken,
            sessionID: sessionID,
            userID: userID,
            userName: userName
        )
    }

    func encode(with coder: NSCoder) {
        fatalError("not needed")
    }

    static func registerNamespacedClassName() {
        NSKeyedUnarchiver.setClass(classForKeyedUnarchiver(), forClassName: "ProtonCoreNetworking.AuthCredential")
    }
}
