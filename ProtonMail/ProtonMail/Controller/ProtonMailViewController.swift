//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import SWRevealViewController

protocol ProtonMailViewControllerProtocol {
    func shouldShowSideMenu() -> Bool
    func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController, style : UIModalPresentationStyle)
}
extension ProtonMailViewControllerProtocol where Self: UIViewController {
    func shouldShowSideMenu() -> Bool {
        return true
    }
    
    func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController, style : UIModalPresentationStyle = .overCurrentContext)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = style
    }
}

class ProtonMailViewController: UIViewController, ProtonMailViewControllerProtocol {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProtonMailViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
    
    class func setup(_ controller: UIViewController,
                     _ menuButton: UIBarButtonItem!,
                     _ shouldShowMenu: Bool) {
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
        
        configureNavigationBar(controller)
        controller.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
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

}


// FIXME: this is a temporary class. refactor it later
class ProtonMailTabBarController: UITabBarController, ProtonMailViewControllerProtocol {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProtonMailTabBarController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
    
    class func setup(_ controller: UIViewController,
                     _ menuButton: UIBarButtonItem!,
                     _ shouldShowMenu: Bool) {
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
        
        configureNavigationBar(controller)
        controller.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func configureNavigationBar() {
        ProtonMailTabBarController.configureNavigationBar(self)
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
    
}
