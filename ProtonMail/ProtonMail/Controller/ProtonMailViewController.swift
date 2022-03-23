//
//  ProtonMailViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

#if !APP_EXTENSION
import SideMenuSwift
import ProtonCore_UIFoundations
#endif

protocol ProtonMailViewControllerProtocol {
    func shouldShowSideMenu() -> Bool
    func setPresentationStyleForSelfController(_ selfController: UIViewController, presentingController: UIViewController, style: UIModalPresentationStyle)
}
extension ProtonMailViewControllerProtocol where Self: UIViewController {
    func shouldShowSideMenu() -> Bool {
        return true
    }

    func setPresentationStyleForSelfController(_ selfController: UIViewController,
                                               presentingController: UIViewController,
                                               style: UIModalPresentationStyle = .overCurrentContext) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = style
    }
}

extension UIViewController {
    class func setup(_ controller: UIViewController,
                     _ menuButton: UIBarButtonItem!,
                     _ shouldShowMenu: Bool) {
        #if !APP_EXTENSION
        if controller.sideMenuController != nil {
            if shouldShowMenu && menuButton != nil {
                controller.navigationItem.leftBarButtonItem = menuButton
                menuButton.accessibilityLabel = LocalString._menu_button
                menuButton.action = #selector(self.openMenu)
            }
        }
        #endif

        UIViewController.configureNavigationBar(controller)
        controller.setNeedsStatusBarAppearanceUpdate()
    }

    #if !APP_EXTENSION
    @objc func openMenu() {
        sideMenuController?.revealMenu()
    }
    #endif

    class func configureNavigationBar(_ controller: UIViewController) {
        #if !APP_EXTENSION
        var attribute = FontManager.DefaultStrong
        attribute[.foregroundColor] = ColorProvider.TextNorm
        controller.navigationController?.navigationBar.titleTextAttributes = attribute
        controller.navigationController?.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        controller.navigationController?.navigationBar.tintColor = ColorProvider.TextNorm
        #else
        controller.navigationController?.navigationBar.barTintColor = UIColor(named: "launch_background_color")
        controller.navigationController?.navigationBar.tintColor = UIColor(named: "launch_text_color")
        #endif

        controller.navigationController?.navigationBar.isTranslucent = false
        controller.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)// Hide shadow
        controller.navigationController?.navigationBar.shadowImage = UIImage()// Hide shadow
        controller.navigationController?.navigationBar.layoutIfNeeded()

        let navigationBarTitleFont = Fonts.h3.semiBold
        #if !APP_EXTENSION
        controller.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: ColorProvider.TextNorm,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        #else
        controller.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "launch_text_color")!,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        #endif
    }

    func emptyBackButtonTitleForNextView() {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }

    var isOnline: Bool {
        guard let reachability = Reachability.forInternetConnection(),
              reachability.currentReachabilityStatus() != .NotReachable else {
            return false
        }
        return true
    }
}

class ProtonMailViewController: UIViewController, ProtonMailViewControllerProtocol, AccessibleView {

    @IBOutlet weak var menuButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        generateAccessibilityIdentifiers()
    }

    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        if #available(iOS 13.0, *) {
            if let vc = self.presentationController {
                self.presentationController?.delegate?.presentationControllerWillDismiss?(vc)
            }
        }
    }
}

class ProtonMailTableViewController: UITableViewController, ProtonMailViewControllerProtocol, AccessibleView {

    @IBOutlet weak var menuButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        generateAccessibilityIdentifiers()
    }
}
