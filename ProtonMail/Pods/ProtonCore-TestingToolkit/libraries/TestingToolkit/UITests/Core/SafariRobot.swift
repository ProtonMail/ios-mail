//
//  SafariRobot.swift
//  ProtonCore-TestingToolkit-UITests-Core - Created on 20.10.22.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if canImport(fusion)

import fusion
import XCTest

public final class SafariRobot: CoreElements {

    public let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func isOutsideOfApplication() -> SafariRobot {
            let application = XCUIApplication()
            XCTAssertTrue(application.wait(for: .runningBackground, timeout: 10))
            XCTAssertTrue(application.state == .runningBackground)
            return SafariRobot()
        }
    }
}

#endif
