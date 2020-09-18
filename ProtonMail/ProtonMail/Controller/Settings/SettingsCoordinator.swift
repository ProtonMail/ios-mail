//
//  SettingsCoordinator.swift
//  ProtonMail - Created on 12/12/18.
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
    

import Foundation
import SWRevealViewController

class SettingsCoordinator: SWRevealCoordinator {
    typealias VC = SettingsTableViewController
    
    let viewModel : SettingsViewModel
    var services: ServiceFactory
    
    internal weak var viewController: SettingsTableViewController?
    internal weak var navigation: UIViewController?
    internal weak var swRevealVC: SWRevealViewController?
    internal weak var deepLink: DeepLink?
    
    lazy internal var configuration: ((SettingsTableViewController) -> ())? = { [unowned self] vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }
    
    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
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
    
    init(vc: SettingsTableViewController, vm: SettingsViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    init(rvc: SWRevealViewController?, nav: UIViewController?, vc: SettingsTableViewController, vm: SettingsViewModel, services: ServiceFactory, deeplink: DeepLink?) {
        self.navigation = nav
        self.swRevealVC = rvc
        self.viewModel = vm
        self.viewController = vc
        self.deepLink = deeplink
        self.services = services
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
            
            let user = services.get(by: UsersManager.self).firstUser!
            next.viewModel = LabelManagerViewModelImpl(apiService: user.apiService, labelService: user.labelService, coreDataService: services.get())
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
//            guard let next = destination as? ChangePasswordViewController else {
//                return false
//            }
//            next.setViewModel(shareViewModelFactoy.getChangeSinglePassword())
            return false
        case .snooze:
            break
        }
        
        
        return true
    }
}

