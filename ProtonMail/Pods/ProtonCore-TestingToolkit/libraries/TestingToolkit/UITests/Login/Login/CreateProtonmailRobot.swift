//
//  CreateProtonmailRobot.swift
//  ProtonCore-TestingToolkit - Created on 07.05.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import pmtest

private let createProtonmailTitleId = "ChooseUsernameViewController.titleLabel"
private let usernameFieldId = "ChooseUsernameViewController.addressTextField.textField"
private let buttonNextId = "ChooseUsernameViewController.nextButton"
private let buttonCreateAddressId = "CreateAddressViewController.createButton"
private let createPMAddressTitle = "Create ProtonMail address"

public final class CreateProtonmailRobot: CoreElements {
    
    public func fillPMUsername(username: String) -> CreateProtonmailRobot {
        textField(usernameFieldId).wait().tap().typeText(username)
        return self
    }
    
    public func pressNextButton() -> CreateProtonmailRobot {
        button(buttonNextId).tap()
        return self
    }
    
    public func pressCreateAddress<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(buttonCreateAddressId).wait().tap()
        return Robot()
    }
    
    public func createPMAddressIsShown() {
            staticText(createPMAddressTitle).wait().checkExists()
    }
}
