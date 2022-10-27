// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations

extension UIViewController {
    class func setup(_ controller: UIViewController) {
        Self.configureNavigationBar(controller)
        controller.setNeedsStatusBarAppearanceUpdate()
    }

    class func configureNavigationBar(_ controller: UIViewController) {
        var attribute = FontManager.DefaultStrong
        attribute[.foregroundColor] = ColorProvider.TextNorm as UIColor
        controller.navigationController?.navigationBar.titleTextAttributes = attribute
        controller.navigationController?.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        controller.navigationController?.navigationBar.tintColor = ColorProvider.TextNorm

        controller.navigationController?.navigationBar.isTranslucent = false
        controller.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)// Hide shadow
        controller.navigationController?.navigationBar.shadowImage = UIImage()// Hide shadow
        controller.navigationController?.navigationBar.layoutIfNeeded()

        let navigationBarTitleFont = Fonts.h3.semiBold
        let foregroundColor = ColorProvider.TextNorm as UIColor

        controller.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: foregroundColor,
            .font: navigationBarTitleFont
        ]
    }

    func emptyBackButtonTitleForNextView() {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }
}
