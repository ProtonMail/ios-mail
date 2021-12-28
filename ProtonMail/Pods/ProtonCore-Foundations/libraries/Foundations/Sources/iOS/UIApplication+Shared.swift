//
//  UIApplication+helper.swift
//  ProtonCore-Foundations - Created on 28.03.21.
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

import UIKit

public extension UIApplication {
    /// A hacky way to get shared instance
    /// UIApplication.shared can't be used in share extension
    static func getInstance() -> UIApplication? {
        return UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }

    static func openURLIfPossible(_ url: URL) {
        let selector = Selector("openURL:")
        if UIApplication.getInstance()?.responds(to: selector) == true {
            UIApplication.getInstance()?.perform(selector, with: url as NSURL)
        }
    }
}
