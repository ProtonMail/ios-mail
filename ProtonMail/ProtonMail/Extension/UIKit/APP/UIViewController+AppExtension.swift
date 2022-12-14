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
import UIKit

extension UIViewController {
    var isOnline: Bool {
        guard let reachability = Reachability.forInternetConnection(),
              reachability.currentReachabilityStatus() != .NotReachable else {
            return false
        }
        return true
    }

    func setPresentationStyleForSelfController(_ selfController: UIViewController,
                                               presentingController: UIViewController,
                                               style: UIModalPresentationStyle = .overCurrentContext) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = style
    }

    func setupMenuButton() {
        let menuButton = UIBarButtonItem(
            image: IconProvider.hamburger,
            style: .plain,
            target: self,
            action: #selector(self.openMenu)
        )
        menuButton.accessibilityLabel = LocalString._menu_button
        navigationItem.leftBarButtonItem = menuButton
    }

    @objc
    func openMenu() {
        sideMenuController?.revealMenu()
    }
}
