//
//  ProtonMailViewController.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import SWRevealViewController

///Notes:: can't use it because the generac class can't do extension with @objc functions. like tableviewdelegate
class ViewController<T_vm, T_Coordinator : CoordinatorNew> : UIViewController, ViewModelProtocolNew, CoordinatedNew {
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
}


class ProtonMailViewController: UIViewController, ProtonMailViewControllerProtocol {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }
    

}

class ProtonMailTableViewController: UITableViewController, ProtonMailViewControllerProtocol {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}


// FIXME: this is a temporary class. refactor it later
class ProtonMailTabBarController: UITabBarController, ProtonMailViewControllerProtocol {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
