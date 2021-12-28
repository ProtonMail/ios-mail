//
//  ForceUpgradeHelper.swift
//  ProtonCore-ForceUpgrade - Created on 23/10/20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
import ProtonCore_Networking

public enum ForceUpgradeConfig {
    case mobile(URL)
    case desktop
}

public protocol ForceUpgradeController {
    func performForceUpgrade(message: String, config: ForceUpgradeConfig, responseDelegate: ForceUpgradeResponseDelegate?)
}

public class ForceUpgradeHelper: ForceUpgradeDelegate {
    fileprivate let controller: ForceUpgradeController
    fileprivate let config: ForceUpgradeConfig
    fileprivate weak var responseDelegate: ForceUpgradeResponseDelegate?

    public init(config: ForceUpgradeConfig, controller: ForceUpgradeController, responseDelegate: ForceUpgradeResponseDelegate? = nil) {
        self.controller = controller
        self.config = config
        self.responseDelegate = responseDelegate
    }

    public func onForceUpgrade(message: String) {
        controller.performForceUpgrade(message: message, config: config, responseDelegate: responseDelegate)
    }

}
