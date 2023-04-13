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

// sourcery: mock
protocol AppRatingStatusProvider: AnyObject {
    func isAppRatingEnabled() -> Bool
    func setIsAppRatingEnabled(_ value: Bool)
    func hasAppRatingBeenShownInCurrentVersion() -> Bool
    func setAppRatingAsShownInCurrentVersion()
}

extension UserCachedStatus: AppRatingStatusProvider {

    private var currentVersion: String {
        Bundle.main.bundleShortVersion
    }

    func isAppRatingEnabled() -> Bool {
        getShared().bool(forKey: Key.isAppRatingEnabled)
    }

    func setIsAppRatingEnabled(_ value: Bool) {
        getShared().set(value, forKey: Key.isAppRatingEnabled)
    }

    func hasAppRatingBeenShownInCurrentVersion() -> Bool {
        guard let ratingPromptedAtVersion = getShared().string(forKey: Key.appRatingPromptedInVersion) else {
            return false
        }
        return ratingPromptedAtVersion == currentVersion
    }

    func setAppRatingAsShownInCurrentVersion() {
        getShared().setValue(currentVersion, forKey: Key.appRatingPromptedInVersion)
    }
}
