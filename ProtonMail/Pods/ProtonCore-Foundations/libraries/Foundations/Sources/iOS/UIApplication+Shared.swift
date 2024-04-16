//
//  UIApplication+helper.swift
//  ProtonCore-Foundations - Created on 28.03.21.
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

#if os(iOS)
import UIKit

public extension UIApplication {
    /// A hacky way to get shared instance
    /// UIApplication.shared can't be used in share extension
    static func getInstance() -> UIApplication? {
        return UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }

    static func openURLIfPossible(_ url: URL) {
        // Can't use `#selector("openURL:")` here because this Swift error emerges:
        // Argument of '#selector' does not refer to an '@objc' method, property, or initializer
        let selector = NSSelectorFromString("openURL:")
        if UIApplication.getInstance()?.responds(to: selector) == true {
            UIApplication.getInstance()?.perform(selector, with: url as NSURL)
        }
    }

    // Replacement for `UIAppplication.shared.keyWindow` because `UIApplication.shared.keyWindow` is deprecated.
    static var firstKeyWindow: UIWindow? {
        guard let application = UIApplication.getInstance() else { return nil }
        return application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
#endif
