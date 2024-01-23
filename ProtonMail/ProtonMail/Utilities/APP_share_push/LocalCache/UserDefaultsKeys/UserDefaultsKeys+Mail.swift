// Copyright (c) 2023 Proton Technologies AG
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

extension UserDefaultsKeys {
    static let appRatingPromptedInVersion = plainKey(named: "appRatingPromptedInVersion", ofType: String.self)

    static let failedPushNotificationDecryption = plainKey(named: "failedPushNotificationDecryption", ofType: Bool.self)

    static let isAppRatingEnabled = plainKey(named: "isAppRatingEnabled", defaultValue: false)

    static let primaryUserSessionId = plainKey(named: "primary_user_session_id", ofType: String.self)
}
