//
//  SettingsCoordinator.swift
//  ProtonMail - Created on 12/12/18.
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
    

import Foundation
import SWRevealViewController

class SettingsCoordinator: SWRevealCoordinator {
    typealias VC = SettingsTableViewController
    
    let viewModel : SettingsViewModel
    
    internal weak var viewController: SettingsTableViewController?
    internal weak var navigation: UINavigationController?
    internal weak var swRevealVC: SWRevealViewController?
    

    lazy internal var configuration: ((SettingsTableViewController) -> ())? = { vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }
    
    enum Destination : String {
        case notification    = "setting_notification"
        case displayName     = "setting_displayname"
        case signature       = "setting_signature"
        case mobileSignature = "setting_mobile_signature"
        case debugQueue      = "setting_debug_queue_segue"
        case pinCode         = "setting_setup_pingcode"
        case lableManager    = "toManagerLabelsSegue"
        case loginPwd        = "setting_login_pwd"
        case mailboxPwd      = "setting_mailbox_pwd"
        case singlePwd       = "setting_single_password_segue"
        case snooze          = "setting_notifications_snooze_segue"
    }
    
    init(rvc: SWRevealViewController?, nav: UINavigationController?, vc: SettingsTableViewController, vm: SettingsViewModel) {
        self.navigation = nav
        self.swRevealVC = rvc
        self.viewModel = vm
        self.viewController = vc
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        

        
        switch dest {
        case .notification:
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
        case .displayName:
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeDisplayName())
        case .signature:
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeSignature())
        case .mobileSignature:
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeMobileSignature())
        case .debugQueue:
            break
        case .pinCode:
            guard let next = destination as? PinCodeViewController else {
                return false
            }
            next.viewModel = SetPinCodeModelImpl()
        case .lableManager:
            guard let next = destination as? LablesViewController else {
                return false
            }
            next.viewModel = LabelManagerViewModelImpl()
        //self.setPresentationStyleForSelfController(self, presentingController: vc)
        case .loginPwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
        case .mailboxPwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
        case .singlePwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            next.setViewModel(shareViewModelFactoy.getChangeSinglePassword())
        case .snooze:
            break
            //                if #available(iOS 10, *), sender is NotificationsSnoozer {
            //                    super.viewDidLoad()
            //                    self.updateTitle()
            //                    navigationController?.setNavigationBarHidden(false, animated: true)
            //                }
            
            //        case kNotificationsSnoozeSegue: // this allows to setup navbar for deeplink when view of this controller does not load/appear
            //                if #available(iOS 10, *), sender is NotificationsSnoozer {
            //                    super.viewDidLoad()
            //                    self.updateTitle()
            //                    navigationController?.setNavigationBarHidden(false, animated: true)
            //                }
        }
        
        
        return true
    }
}

