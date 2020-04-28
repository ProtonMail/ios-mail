//
//  SettingsDeviceCoordinator.swift
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

class SettingsDeviceCoordinator: SWRevealCoordinator {
    typealias VC = SettingsDeviceViewController
    
    enum Destination : String {
        case accountSetting = "settings_account_settings"
        case autoLock       = "settings_auto_lock"
        case combineContact = "settings_combine_contact"
        
//        case displayName     = "setting_displayname"
//        case signature       = "setting_signature"
//        case mobileSignature = "setting_mobile_signature"
//        case debugQueue      = "setting_debug_queue_segue"
//        case pinCode         = "setting_setup_pingcode"
//        case lableManager    = "toManagerLabelsSegue"
//        case loginPwd        = "setting_login_pwd"
//        case mailboxPwd      = "setting_mailbox_pwd"
//        case singlePwd       = "setting_single_password_segue"
//        case snooze          = "setting_notifications_snooze_segue"
    }
    
    let viewModel : SettingsDeviceViewModel
    var services : ServiceFactory
    
    internal weak var viewController: SettingsDeviceViewController?
    internal weak var navigation: UIViewController?
    internal weak var swRevealVC: SWRevealViewController?
    internal weak var deepLink: DeepLink?
    
    lazy internal var configuration: ((SettingsDeviceViewController) -> ())? = { vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }
    
    init?(rvc: SWRevealViewController?, nav: UINavigationController,
          vm: SettingsDeviceViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
        guard let next = nav.firstViewController() as? VC else {
            return nil
        }
        
        self.navigation = nav
        self.swRevealVC = rvc
        self.viewController = next
        self.viewModel = vm
        self.services = services
    }
    
    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }

    
    init(vc: SettingsDeviceViewController, vm: SettingsDeviceViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    init(rvc: SWRevealViewController?, nav: UIViewController?, vc: SettingsDeviceViewController, vm: SettingsDeviceViewModel, services: ServiceFactory, deeplink: DeepLink?) {
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
            return false
        }
        switch dest {
        case .accountSetting:
            let users : UsersManager = sharedServices.get()
            let vm = SettingsAccountViewModelImpl(user: users.firstUser!)
            guard let accountSetting = SettingsAccountCoordinator(dest: destination, vm: vm, services: self.services) else {
                return false
            }
            accountSetting.start()
            return true

        case .autoLock:
            let users : UsersManager = sharedServices.get()
            let vm = SettingsLockViewModelImpl(user: users.firstUser!)
            guard let lockSetting = SettingsLockCoordinator(dest: destination, vm: vm, services: self.services) else {
                return false
            }
            lockSetting.start()
            return true
        case .combineContact:
            if let vc = destination as? SettingsContactCombineViewController {
                let users : UsersManager = sharedServices.get()
                let vm = SettingsCombineContactViewModel(users: users)
                vc.set(viewModel: vm)
                vc.set(coordinator: self)
                return true
            }
            return false
        }
    }
}

