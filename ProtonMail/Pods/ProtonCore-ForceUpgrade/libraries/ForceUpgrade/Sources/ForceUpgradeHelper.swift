//
//  ForceUpgradeHelper.swift
//  ProtonMail - Created on 23/10/20.
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Networking

public enum ForceUpgradeConfig {
    case mobile(URL)
    case desktop
}

public class ForceUpgradeHelper: ForceUpgradeDelegate {
    fileprivate let coordinator: ForceUpgradeController
    fileprivate let config: ForceUpgradeConfig
    fileprivate weak var responseDelegate: ForceUpgradeResponseDelegate?

    public init(config: ForceUpgradeConfig, responseDelegate: ForceUpgradeResponseDelegate? = nil) {
        self.coordinator = ForceUpgradeController()
        self.config = config
        self.responseDelegate = responseDelegate
    }

    public func onForceUpgrade(message: String) {
        coordinator.performForceUpgrade(message: message, config: config, responseDelegate: responseDelegate)
    }

}
