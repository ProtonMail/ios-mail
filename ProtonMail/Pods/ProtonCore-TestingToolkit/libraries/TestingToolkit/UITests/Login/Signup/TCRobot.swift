//
//  TCRobot.swift
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
import ProtonCore_CoreTranslation

private let titleId = CoreString._su_terms_conditions_view_title
private let backtButtonId = "UINavigationItem.leftBarButtonItem"
private let webViewId = "TCViewController.webView"

public final class TCRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func tcScreenIsShown() -> TCRobot {
            staticText(titleId).wait().checkExists()
            return TCRobot()
        }
    }
    
    public func swipeUpWebView() -> TCRobot {
        webView(webViewId).swipeUp()
        return self
    }
    
    public func backButton() -> RecoveryRobot {
        button(backtButtonId).hasLabel("ic Cross small").tap()
        return RecoveryRobot()
    }
    
}
