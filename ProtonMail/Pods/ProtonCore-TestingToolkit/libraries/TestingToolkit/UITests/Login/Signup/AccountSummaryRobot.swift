//
//  EmailVerificationRobot.swift
//  ProtonCore-TestingToolkit - Created on 19.04.2021.
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

import Foundation
import pmtest

private let congratulationHeaderId = "SummaryViewController.header"
private let accountCreationLabel = "SummaryViewController.descriptionLabel"
private let welcomeLabel = "SummaryViewController.welcomeLabel"
private let startUsingAppButtonId = "SummaryViewController.startButton"

public final class AccountSummaryRobot: CoreElements {
    
    public func accountSummaryElementsDisplayed<T: CoreElements>(robot _: T.Type) -> T {
        staticText(congratulationHeaderId).wait(time: 120).checkExists()
        staticText(accountCreationLabel).checkExists()
        staticText(welcomeLabel).checkExists()
        return T()
    }
    
    public func startUsingAppTap<T: CoreElements>(robot _: T.Type) -> T{
        button(startUsingAppButtonId).wait().tap()
        return T()
    }
}
