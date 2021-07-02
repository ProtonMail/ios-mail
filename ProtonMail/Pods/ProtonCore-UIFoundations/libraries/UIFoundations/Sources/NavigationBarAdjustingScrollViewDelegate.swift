//
//  NavigationBarAdjustingScrollViewDelegate.swift
//  ProtonCore-Login - Created on 29.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit

public final class NavigationBarAdjustingScrollViewDelegate: NSObject, UIScrollViewDelegate {

    private var shouldAdjustNavigationBar = true

    private weak var navigationController: LoginNavigationViewController?

    public func setUp(for scrollView: UIScrollView, shouldAdjustNavigationBar: Bool = true, parent: UIViewController?) {
        guard let navigationController = parent as? LoginNavigationViewController else { return }
        scrollView.delegate = self
        self.navigationController = navigationController
        self.shouldAdjustNavigationBar = shouldAdjustNavigationBar
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldAdjustNavigationBar, let navigationController = navigationController else { return }
        let adjustedTopOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if adjustedTopOffset <= .zero {
            navigationController.setUpTransparentNavigationBar()
        } else {
            navigationController.setUpOpaqueNavigationBar()
        }
    }
}
