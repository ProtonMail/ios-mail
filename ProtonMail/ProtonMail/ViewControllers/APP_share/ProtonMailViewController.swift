//
//  Proton MailViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations

#if !APP_EXTENSION
import SideMenuSwift
import ProtonCore_UIFoundations
import ProtonCore_DataModel
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
    func setupMenuButton() {
        let menuButton = UIBarButtonItem(
            image: Asset.topMenu.image,
            style: .plain,
            target: self,
            action: #selector(self.openMenu)
        )
        menuButton.accessibilityLabel = LocalString._menu_button
        navigationItem.leftBarButtonItem = menuButton
    }

    @objc func openMenu() {
        sideMenuController?.revealMenu()
    }
    #endif

    class func configureNavigationBar(_ controller: UIViewController) {
        #if !APP_EXTENSION
        var attribute = FontManager.DefaultStrong
        attribute[.foregroundColor] = ColorProvider.TextNorm as UIColor
        controller.navigationController?.navigationBar.titleTextAttributes = attribute
        controller.navigationController?.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        controller.navigationController?.navigationBar.tintColor = ColorProvider.TextNorm
        #else
        controller.navigationController?.navigationBar.barTintColor = UIColor(named: "LaunchScreenBackground")
        controller.navigationController?.navigationBar.tintColor = UIColor(named: "launch_text_color")
        #endif

        controller.navigationController?.navigationBar.isTranslucent = false
        controller.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)// Hide shadow
        controller.navigationController?.navigationBar.shadowImage = UIImage()// Hide shadow
        controller.navigationController?.navigationBar.layoutIfNeeded()

        let navigationBarTitleFont = Fonts.h3.semiBold
        let foregroundColor: UIColor
        #if !APP_EXTENSION
        foregroundColor = ColorProvider.TextNorm
        #else
        foregroundColor = UIColor(named: "launch_text_color")!
        #endif

        controller.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor(named: "launch_text_color")!,
            .font: navigationBarTitleFont
        ]
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
        
        #if !APP_EXTENSION
        if UserInfo.isEncryptedSearchEnabled {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            if let userID = usersManager.firstUser?.userInfo.userId {
                // Check if previous state was low storage
                if EncryptedSearchService.shared.getESState(userID: userID) == .lowstorage {
                    // check if there is already enough disk space and restart indexing
                    if EncryptedSearchService.shared.getFreeDiskSpace() > EncryptedSearchService.shared.lowStorageLimit { // 100 MB
                        EncryptedSearchService.shared.restartIndexBuilding(userID: userID)
                    }
                }
            } 
        }
        #endif
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
