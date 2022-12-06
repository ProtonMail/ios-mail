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

import ProtonCore_Common
import ProtonCore_DataModel

extension UserInfo {
    static var isInAppFeedbackEnabled: Bool {
        if ProcessInfo.isRunningUnitTests {
            return true
        }
        // The `-disableAnimations` flag is set for UI tests runs
        if CommandLine.arguments.contains("-disableAnimations") {
            return false
        }
        return true
    }

    static var isDarkModeEnable: Bool {
        return true
    }

    static var isDiffableDataSourceEnabled: Bool {
        if #available(iOS 13, *) {
            return true
        } else {
            return false
        }
    }

    static var isToolbarCustomizationEnable: Bool {
        if ProcessInfo.isRunningUnitTests {
            return true
        }
        if ProcessInfo.processInfo.arguments.contains(
            BackendConfiguration.Arguments.disableToolbarSpotlight
        ) {
            return false
        }
        return false
    }

    static var isImageProxyAvailable: Bool {
        true
    }

    /// Swipe to show previous / next conversation or messages
    static var isConversationSwipeEnabled: Bool {
        false
    }
}
