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

import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreUIFoundations
import UIKit

extension UIViewController {
    var isOnline: Bool {
        InternetConnectionStatusProvider.shared.status.isConnected
    }

    func setPresentationStyleForSelfController(presentingController: UIViewController,
                                               style: UIModalPresentationStyle = .overCurrentContext) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = style
    }

    func setupMenuButton(userInfo: UserInfo) {
        navigationItem.leftBarButtonItem = makeMenuButton(userInfo: userInfo)
    }

    func makeMenuButton(userInfo: UserInfo) -> UIBarButtonItem {
        let menuButton = UIBarButtonItem(customView: menuButtonUI(userInfo: userInfo))
        menuButton.tintColor = ColorProvider.IconNorm
        return menuButton
    }

    private func menuButtonUI(userInfo: UserInfo) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        let hamburgerButton = UIButton(type: .custom)
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        hamburgerButton.setImage(IconProvider.hamburger, for: .normal)
        hamburgerButton.tintColor = ColorProvider.IconNorm
        hamburgerButton.addTarget(
            self,
            action: #selector(self.openMenu),
            for: .touchUpInside
        )
        hamburgerButton.accessibilityLabel = LocalString._menu_button
        containerView.addSubview(hamburgerButton)
        hamburgerButton.fillSuperview()
        [
            hamburgerButton.widthAnchor.constraint(equalToConstant: 44),
            hamburgerButton.heightAnchor.constraint(equalTo: hamburgerButton.widthAnchor)
        ].activate()

        if isMenuBadgeVisible(userInfo: userInfo) {
            let badge = badgeUI()
            containerView.addSubview(badge)
            [
                badge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
                badge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2)
            ].activate()
        }

        return containerView
    }

    private func badgeUI() -> UIView {
        let height: CGFloat = 8
        let badge = UIView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = ColorProvider.NotificationError
        [
            badge.heightAnchor.constraint(equalToConstant: height),
            badge.widthAnchor.constraint(equalToConstant: height)
        ].activate()
        badge.setCornerRadius(radius: height / 2)
        return badge
    }

    @objc
    func openMenu() {
        sideMenuController?.revealMenu()
    }

    func isMenuBadgeVisible(userInfo: UserInfo) -> Bool {
        guard FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.splitStorage, reloadValue: true),
              !userInfo.isOnAStoragePaidPlan,
              let usedBaseSpace = userInfo.usedBaseSpace,
              let maxBaseSpace = userInfo.maxBaseSpace,
              let usedDriveSpace = userInfo.usedDriveSpace,
              let maxDriveSpace = userInfo.maxDriveSpace else {
            return false
        }

        let mailFactor = CGFloat(usedBaseSpace) / CGFloat(maxBaseSpace)
        let driveFactor = CGFloat(usedDriveSpace) / CGFloat(maxDriveSpace)
        return mailFactor > StorageAlertVisibility.bannerThreshold
        || driveFactor > StorageAlertVisibility.bannerThreshold
    }

    func dismiss(animated: Bool) async {
        await withCheckedContinuation { continuation in
            dismiss(animated: animated, completion: continuation.resume)
        }
    }
}
