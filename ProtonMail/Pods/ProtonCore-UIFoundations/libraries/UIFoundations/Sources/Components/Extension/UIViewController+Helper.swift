//
//  UIViewController+Helper.swift
//  ProtonCore-UIFoundations - Created on 06.04.21.
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
import ProtonCoreFoundations

extension UIViewController {
    public func lockUI() {
        enableUserInteraction(enable: false)
    }

    public func unlockUI() {
        enableUserInteraction(enable: true)
    }

    private func enableUserInteraction(enable: Bool) {
        view.window?.isUserInteractionEnabled = enable
    }
}

public extension UIViewController {

    func setUpCloseButton(showCloseButton: Bool, action: Selector?) {
        if showCloseButton {
            let closeButton = UIBarButtonItem(image: IconProvider.cross, style: .plain, target: self, action: action)
            closeButton.tintColor = ColorProvider.IconNorm
            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.setLeftBarButton(closeButton, animated: true)
            navigationItem.assignNavItemIndentifiers()
        }
    }

    func setUpBackArrow(action: Selector?) {
        let backButton = UIBarButtonItem(image: IconProvider.arrowLeft, style: .plain, target: self, action: action)
        backButton.tintColor = ColorProvider.IconNorm
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.setLeftBarButton(backButton, animated: true)
        navigationItem.assignNavItemIndentifiers()
    }

    func updateTitleAttributes() {
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let textAttributes = [NSAttributedString.Key.foregroundColor: foregroundColor]
        let appearance = navigationController?.navigationBar.standardAppearance
        appearance?.titleTextAttributes = textAttributes
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

    }

    static var topVC: UIViewController? {
        var topViewController: UIViewController?
        let keyWindow = UIApplication.firstKeyWindow
        if var top = keyWindow?.rootViewController {
            while let presentedViewController = top.presentedViewController {
                top = presentedViewController
            }
            topViewController = top
        }

        return topViewController
    }
}

#endif
