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
import SWRevealViewController
#endif

///Notes:: can't use it because the generac class can't do extension with @objc functions. like tableviewdelegate
class ViewController<T_vm, T_Coordinator : CoordinatorNew> : UIViewController, ViewModelProtocol, CoordinatedNew {
    typealias viewModelType = T_vm
    typealias coordinatorType = T_Coordinator
    
    internal var viewModel : T_vm!
    internal var coordinator : T_Coordinator?
    
    func set(viewModel: T_vm) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: T_Coordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.viewModel != nil, "T1 can't be nil")
        assert(self.coordinator != nil, "T2 can't be nil")
    }
}


protocol ProtonMailViewControllerProtocol {
    func shouldShowSideMenu() -> Bool
    func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController, style : UIModalPresentationStyle)
}
extension ProtonMailViewControllerProtocol where Self: UIViewController {
    func shouldShowSideMenu() -> Bool {
        return true
    }
    
    func setPresentationStyleForSelfController(_ selfController : UIViewController,
                                               presentingController: UIViewController,
                                               style : UIModalPresentationStyle = .overCurrentContext) {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = style
    }
}

extension UIViewController {
    class func setup(_ controller: UIViewController,
                     _ menuButton: UIBarButtonItem!,
                     _ shouldShowMenu: Bool) {
        #if !APP_EXTENSION
        if let revealViewController = controller.revealViewController() {
            
            if (shouldShowMenu && menuButton != nil) {
                controller.navigationItem.leftBarButtonItem = menuButton
                menuButton.accessibilityLabel = LocalString._menu_button
                menuButton.target = controller.revealViewController()
                menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
                controller.view.addGestureRecognizer(controller.revealViewController().panGestureRecognizer())
                
                revealViewController.panGestureRecognizer()
                revealViewController.tapGestureRecognizer()
            }
        }
        #endif
        
        UIViewController.configureNavigationBar(controller)
        controller.setNeedsStatusBarAppearanceUpdate()
    }
    
    class func configureNavigationBar(_ controller: UIViewController) {
        controller.navigationController?.navigationBar.barStyle = UIBarStyle.black
        controller.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;//.Blue_475F77
        controller.navigationController?.navigationBar.isTranslucent = false
        controller.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = Fonts.h2.regular
        controller.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
    }
    
    func removePresentedViewController() {
        guard let vc = self.presentedViewController else {return}
        vc.dismiss(animated: true, completion: nil)
    }
}


class ProtonMailViewController: UIViewController, ProtonMailViewControllerProtocol, AccessibleView {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        generateAccessibilityIdentifiers()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}


// FIXME: this is a temporary class. refactor it later
class ProtonMailTabBarController: UITabBarController, ProtonMailViewControllerProtocol, AccessibleView {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        generateAccessibilityIdentifiers()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
