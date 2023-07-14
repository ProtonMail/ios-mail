//
//  UIBarButtonItem+Defaults.swift
//  ProtonCore-UIFoundations - Created on 09.11.2020.
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

public extension UIBarButtonItem {
    static func back(on target: Any?, action: Selector) -> UIBarButtonItem {
        return makeButton(on: target, action: action, image: IconProvider.arrowLeft)
    }

    static func close(on target: Any?, action: Selector) -> UIBarButtonItem {
        return makeButton(on: target, action: action, image: IconProvider.cross)
    }

    static func button(on target: Any?, action: Selector, image: UIImage?) -> UIBarButtonItem {
        return makeButton(on: target, action: action, image: image)
    }

    private static func makeButton(on target: Any?, action: Selector, image: UIImage?) -> UIBarButtonItem {
        let button = UIButton(frame: .zero)
        button.setSizeContraint(height: 22, width: 22)
        button.tintColor = ColorProvider.TextNorm
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
}

#endif
