// Copyright (c) 2024 Proton Technologies AG
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

final class TestService: ApplicationServiceSetUp {
    private let userDefaults = UserDefaults.appGroup

    func setUpService() {
        if userDefaults.bool(forKey: "uiTesting") {
            clearExistingDataIfNecessary()
            disableOnboardingPrompts()
        }
    }

    private func clearExistingDataIfNecessary() {
        if userDefaults.bool(forKey: "forceCleanState") {
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: fileManager.sharedSupportDirectory)
            try? fileManager.removeItem(at: fileManager.sharedCacheDirectory)
        }
    }

    private func disableOnboardingPrompts() {
        userDefaults[.hasSeenAlphaOnboarding] = true
        userDefaults[.notificationAuthorizationRequestDates] = [.now]
    }
}
