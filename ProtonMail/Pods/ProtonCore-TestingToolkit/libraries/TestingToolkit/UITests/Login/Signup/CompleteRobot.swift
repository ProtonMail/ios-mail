//
//  CompleteRobot.swift
//  ProtonCore-TestingToolkit - Created on 21.04.2021.
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

private let titleId = "CompleteViewController.completeTitleLabel"
private let descriptionId = "CompleteViewController.completeDescriptionLabel"

public final class CompleteRobot: CoreElements {

    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func completeScreenIsShown<T: CoreElements>(robot _: T.Type) -> T {
            staticText(titleId).wait().checkExists()
            staticText(descriptionId).checkExists()
            return T()
        }
    }
}
