// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit

extension UIBarButtonItem {

    // After iOS 14, there is a new feature when users long tap the back button
    // It will show the navigation menu
    // But the back button title is empty, so the navigation menu doesn't have any text
    // Since our app is not that deep doesn't get many benefits from it
    // Use the swizzle method to disable the menu for the whole app
    static func enableMenuSwizzle() {
        if #available(iOS 14.0, *) {
            exchange(
                #selector(setter: UIBarButtonItem.menu),
                with: #selector(setter: UIBarButtonItem.swizzledMenu),
                in: UIBarButtonItem.self
            )
        }
    }

    @available(iOS 14.0, *)
    private static func exchange(
        _ selector1: Selector,
        with selector2: Selector,
        in cls: AnyClass
    ) {
        guard
            let method = class_getInstanceMethod(
                cls,
                selector1
            ),
            let swizzled = class_getInstanceMethod(
                cls,
                selector2
            )
        else {
            return
        }
        method_exchangeImplementations(method, swizzled)
    }

    @available(iOS 14.0, *)
    @objc dynamic var swizzledMenu: UIMenu? {
        get {
            return self.swizzledMenu
        }
        set {
            guard let id = newValue?.identifier.rawValue,
                  !id.hasPrefix("com.apple.menu.dynamic") else { return }
            self.swizzledMenu = newValue
        }
    }
}
