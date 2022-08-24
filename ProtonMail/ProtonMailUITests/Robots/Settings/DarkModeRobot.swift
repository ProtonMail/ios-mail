// Copyright (c) 2022 Proton AG
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

import pmtest

fileprivate struct id {
    static let alwaysOnText = "Always on"
    static let alwaysOffText = "Always off"
    static let backButtonText = "Settings"
}

class DarkModeRobot: CoreElements {
    
    func selectAlwaysOn() -> DarkModeRobot {
        staticText(id.alwaysOnText).tap()
        return self
    }
    
    func selectAlwaysOff() -> DarkModeRobot {
        staticText(id.alwaysOffText).tap()
        return self
    }
    
    func navigateBackToSettings() -> SettingsRobot {
        button(id.backButtonText).tap()
        return SettingsRobot()
    }
}
