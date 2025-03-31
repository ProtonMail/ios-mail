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

final class TestService: Sendable {
    static let shared: TestService = .init()
}

extension TestService: ApplicationServiceSetUp {

    #if UITESTS
        func setUpService() {
            try! clearExistingDataIfNecessary()
            disableOnboardingPrompts()
        }

        private func clearExistingDataIfNecessary() throws {
            if let _ = UserDefaults.standard.string(forKey: "forceCleanState") {
                guard let applicationSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                    throw TestServiceError.applicationSupportDirectoryNotAccessible
                }

                guard let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                    throw TestServiceError.cacheDirectoryNotAccessible
                }

                try? FileManager.default.removeItem(atPath: applicationSupportFolder.path())
                try? FileManager.default.removeItem(atPath: cacheFolder.path)
            }
        }

        private func disableOnboardingPrompts() {
            let userDefaults = UserDefaults.standard
            userDefaults.set(false, forKey: "showAlphaV1Onboarding")
            userDefaults.set([Date()], forKey: "notificationAuthorizationRequestDates")
        }

        enum TestServiceError: Error {
            case applicationSupportDirectoryNotAccessible
            case cacheDirectoryNotAccessible
        }
    #else
        func setUpService() {}
    #endif
}
