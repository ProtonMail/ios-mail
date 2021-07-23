//
//  PMTabBarBuilder.swift
//  ProtonCore-UIFoundations - Created on 18.08.20.
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

public final class PMTabBarBuilder {
    private var items: [PMTabBarItem] = []
    private var height: CGFloat = 48
    private var backgroundColor: UIColor = BackgroundColors._ActionBar
    private var floatingHeight: CGFloat?
    private var vcs: [UIViewController] = []
    private var selectedIndex: Int = 0

    public init() {}

    /// Sets height of the tab bar controller, default value is `48`
    public func setTabBarHeight(_ height: CGFloat) -> PMTabBarBuilder {
        self.height = height
        return self
    }

    /// Sets background color of the tab bar controller, default value is `BackgroundColors._ActionBar`
    public func setBackgroundColor(_ color: UIColor) -> PMTabBarBuilder {
        self.backgroundColor = color
        return self
    }

    /// Sets floating height of the tab bar controller
    /// - Parameter value: The floating distance between the tab bar and the bottom of the screen, default value is `nil`, which means the bar won't float.
    public func setFloatingHeight(_ value: CGFloat) -> PMTabBarBuilder {
        self.floatingHeight = value
        return self
    }

    /// The index of the selected tab item when initializing. default value is `0`
    public func setSelectedIndex(_ idx: Int) -> PMTabBarBuilder {
        self.selectedIndex = idx
        return self
    }

    /// Sets tab bar item and view controller pairs
    public func addItem(_ item: PMTabBarItem, withController vc: UIViewController) -> PMTabBarBuilder {
        self.items.append(item)
        self.vcs.append(vc)
        return self
    }

    /// Build an instance of `PMTabBarController` by the previous configuration.
    public func build() throws -> PMTabBarController {
        guard self.items.count > 0, self.vcs.count > 0 else {
            throw PMTabBarError.emptyItemAndVC
        }

        let config = PMTabBarConfig(items: self.items,
                                    height: self.height,
                                    backgroundColor:
                                        self.backgroundColor,
                                    floatingHeight: self.floatingHeight)
        let barVC = PMTabBarController()
        try barVC.setupConfig(config)
        barVC.setViewControllers(self.vcs, animated: false)
        barVC.selectedIndex = self.selectedIndex
        return barVC
    }
}
