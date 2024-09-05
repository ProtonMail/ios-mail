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

import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel

struct UpsellButtonStateProvider {
    typealias Dependencies = AnyObject & HasFeatureFlagProvider & HasUserDefaults & HasUserManager

    private let calendar = Calendar.autoupdatingCurrent
    private unowned let dependencies: Dependencies

    private let currentDate: () -> Date

    private static func cryptoBasedCurrentDate() -> Date {
        Date(timeIntervalSince1970: TimeInterval(CryptoGo.CryptoGetUnixTime()))
    }

    private var currentUserID: String {
        dependencies.user.userID.rawValue
    }

    private var timeBeforeShowingUpsellAgain: DateComponents {
        var dateComponents = DateComponents()

        // facilitate manual testing and QA
        if Application.isDebug && !ProcessInfo.isRunningUnitTests {
            dateComponents.second = 30
        } else if Application.isDebugOrEnterprise && !ProcessInfo.isRunningUnitTests {
            dateComponents.minute = 5
        } else {
            dateComponents.day = 10
        }

        return dateComponents
    }

    init(dependencies: Dependencies, currentDate: @escaping () -> Date = cryptoBasedCurrentDate) {
        self.dependencies = dependencies
        self.currentDate = currentDate
    }

    var shouldShowUpsellButton: Bool {
        guard
            dependencies.featureFlagProvider.isEnabled(.upsellButton),
            dependencies.user.userInfo.subscribed.isEmpty
        else {
            return false
        }

        if dependencies.featureFlagProvider.isEnabled(.alwaysShowUpsellButton) {
            return true
        }

        let upsellButtonDismissalDatesPerUserID = dependencies.userDefaults[.upsellButtonDismissalDatesPerUserID]

        guard let dateWhenUpsellButtonWasLastDismissed = upsellButtonDismissalDatesPerUserID[currentUserID] else {
            return true
        }

        let dateWhenUpsellButtonShouldBeShownAgain = calendar.date(
            byAdding: timeBeforeShowingUpsellAgain,
            to: dateWhenUpsellButtonWasLastDismissed
        ).unsafelyUnwrapped

        return dateWhenUpsellButtonShouldBeShownAgain <= currentDate()
    }

    func upsellButtonWasTapped() {
        dependencies.userDefaults[.upsellButtonDismissalDatesPerUserID][currentUserID] = currentDate()
    }
}
