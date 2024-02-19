// Copyright (c) 2021 Proton AG
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

extension ProcessInfo {
    enum LaunchArgument: String {
        case disableToolbarSpotlight = "-toolbarSpotlightOff"
        case showReferralPromptView = "-showReferralPromptView"
        case uiTests = "-uiTests"
    }

    static var isRunningUnitTests: Bool {
        return processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var isRunningUITests: Bool {
        hasLaunchArgument(.uiTests)
    }

    static var launchArguments: [String] {
        processInfo.arguments
    }

    static func hasLaunchArgument(_ argument: LaunchArgument) -> Bool {
        launchArguments.contains(argument.rawValue)
    }
}
