// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

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
#if DEBUG
        return true
#else
        return false
#endif
    }

    static var isDarkModeEnable: Bool {
        return true
    }

    static var isDiffableDataSourceEnabled: Bool {
        if #available(iOS 13, *) {
            return false
        } else {
            return false
        }
    }
}
