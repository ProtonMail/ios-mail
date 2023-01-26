//
//  PMTabBarConfig.swift
//  ProtonCore-UIFoundations - Created on 15.07.20.
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

import UIKit

struct PMTabBarConfig {
    /// Height of tabbar
    let height: CGFloat
    /// Background color of tabbar
    let backgroundColor: UIColor
    /// The floating distance between the tab bar and the bottom of the screen
    let floatingHeight: CGFloat?
    /// Is float tabbar
    var isFloat: Bool {
        return self.floatingHeight != nil
    }
    /// Items of tabbar
    let items: [PMTabBarItem]

    /// Initializer of tabbar config
    /// - Parameters:
    ///   - items: Tabbar items, note the number of items must equal number of viewcontrollers, or it will cause error
    ///   - height: Height of tabbar, default value is `48`
    ///   - backgroundColor: Background color of tabbar, default value is `ColorProvider.FloatyBackground`
    ///   - floatingHeight: The floating distance between the tab bar and the bottom of the screen. If the `floatingHeight` is `nil`, then the tab bar won't float. Otherwise, the tab bar will be floating with the designated height. Default value is `nil`, which means the bar won't float.
    init(items: [PMTabBarItem], height: CGFloat?=nil, backgroundColor: UIColor?=nil, floatingHeight: CGFloat?=nil) {
        self.items = items
        self.height = height ?? 48
        self.floatingHeight = floatingHeight
        self.backgroundColor = backgroundColor ?? ColorProvider.FloatyBackground
    }
}

public struct PMTabBarItem {
    let color: UIColor
    let selectedColor: UIColor
    let selectedBgColor: UIColor
    let title: String?
    let icon: UIImage?

    /// Initialize `PMTabBarItem` with title string
    /// - Parameters:
    ///   - title: Item title
    ///   - color: Title color in normal status, default value is `ColorProvider.FloatyText`
    ///   - selectedColor: Title color in selected status, default value is `.white`
    ///   - selectedBgColor: Background color in selected status, default value is `ColorProvider.FloatyPressed`
    public init(title: String, color: UIColor?=nil, selectedColor: UIColor?=nil, selectedBgColor: UIColor?=nil) {
        self.title = title
        self.color = color ?? ColorProvider.FloatyText
        self.selectedColor = selectedColor ?? .white
        self.selectedBgColor = selectedBgColor ?? ColorProvider.FloatyPressed
        self.icon = nil
    }

    /// Initialize `PMTabBarItem` with icon image
    /// - Parameters:
    ///   - icon: Item icon image
    ///   - color: Title color in normal status, default value is `ColorProvider.FloatyText`
    ///   - selectedColor: Title color in selected status, default value is `.white`
    ///   - selectedBgColor: Background color in selected status, default value is `ColorProvider.FloatyPressed`
    public init(icon: UIImage, color: UIColor?=nil, selectedColor: UIColor?=nil, selectedBgColor: UIColor?=nil) {
        self.icon = icon
        self.color = color ?? ColorProvider.FloatyText
        self.selectedColor = selectedColor ?? .white
        self.selectedBgColor = selectedBgColor ?? ColorProvider.FloatyPressed
        self.title = nil
    }
}
