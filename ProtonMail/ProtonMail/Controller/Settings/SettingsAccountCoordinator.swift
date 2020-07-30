//
//  SettingsAccountCoordinator.swift
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

class SettingsAccountCoordinator: DefaultCoordinator {

    typealias VC = SettingsAccountViewController
    
    let viewModel : SettingsAccountViewModel
    var services: ServiceFactory
    
    internal weak var viewController: SettingsAccountViewController?
    internal weak var deepLink: DeepLink?
    
    lazy internal var configuration: ((SettingsAccountViewController) -> ())? = { vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }
    
    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }
    
    enum Destination : String {
        case recoveryEmail = "setting_notification"//"recoveryEmail"
        case loginPwd      = "setting_login_pwd"
        case mailboxPwd    = "setting_mailbox_pwd"
        case singlePwd     = "setting_single_password_segue"
        case displayName   = "setting_displayname"
        case signature     = "setting_signature"
        case mobileSignature = "setting_mobile_signature"
        case lableManager    = "toManagerLabelsSegue"
        
//        case notification    = "setting_notification"
//        case debugQueue      = "setting_debug_queue_segue"
//        case pinCode         = "setting_setup_pingcode"
//        case lableManager    = "toManagerLabelsSegue"
//        case loginPwd        = "setting_login_pwd"
//        case mailboxPwd      = "setting_mailbox_pwd"
//        case singlePwd       = "setting_single_password_segue"
//        case snooze          = "setting_notifications_snooze_segue"
        case swipingGesture = "setting_swiping_gesture"
        case privacy = "setting_privacy"
    }
    
    init?(dest: UIViewController, vm: SettingsAccountViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
        guard let next = dest as? VC else {
            return nil
        }
        self.viewController = next
        self.viewModel = vm
        self.services = services
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .swipingGesture:
            openGesture()
        case .privacy:
            openPrivacy()
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .recoveryEmail:
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            let users: UsersManager = services.get()
            next.setViewModel(ChangeNotificationEmailViewModel(user: users.firstUser!))
        case .displayName:
            let users: UsersManager = services.get()
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(ChangeDisplayNameViewModel(user: users.firstUser!))
        case .signature:
            let users: UsersManager = services.get()
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(ChangeSignatureViewModel(user: users.firstUser!))
        case .mobileSignature:
            let users: UsersManager = services.get()
            guard let next = destination as? SettingDetailViewController else {
                return false
            }
            next.setViewModel(ChangeMobileSignatureViewModel(user: users.firstUser!))
//        case .debugQueue:
//            break
//        case .pinCode:
//            guard let next = destination as? PinCodeViewController else {
//                return false
//            }
//            next.viewModel = SetPinCodeModelImpl()
        case .lableManager:
            guard let next = destination as? LablesViewController else {
                return false
            }
            
            let users : UsersManager = services.get()
            let user = users.firstUser!
            next.viewModel = LabelManagerViewModelImpl(apiService: user.apiService, labelService: user.labelService)
//        case .loginPwd:
//            guard let next = destination as? ChangePasswordViewController else {
//                return false
//            }
//            next.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
//        case .mailboxPwd:
//            guard let next = destination as? ChangePasswordViewController else {
//                return false
//            }
//            next.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
//        case .singlePwd:
//            guard let next = destination as? ChangePasswordViewController else {
//                return false
//            }
//            next.setViewModel(shareViewModelFactoy.getChangeSinglePassword())
//        case .snooze:
//            break
        case .loginPwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            let users: UsersManager = services.get()
            next.setViewModel(ChangeLoginPWDViewModel(user: users.firstUser!))
        case .mailboxPwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            let users: UsersManager = services.get()
            next.setViewModel(ChangeMailboxPWDViewModel(user: users.firstUser!))
        case .singlePwd:
            guard let next = destination as? ChangePasswordViewController else {
                return false
            }
            let users: UsersManager = services.get()
            next.setViewModel(ChangeSinglePasswordViewModel(user: users.firstUser!))
        case .swipingGesture:
            break
        case .privacy:
            break
        }
        return true
    }
    
    private func openGesture() {
        let vc = SettingsGesturesViewController()
        let users: UsersManager = services.get()
        let user = users.firstUser!
        let coordinator = SettingsGesturesCoordinator(dest: vc, vm: SettingsGestureViewModelImpl(user: user, users: users), services: self.services)
        coordinator?.start()
        self.viewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    private func openPrivacy() {
        let vc = SettingsPrivacyViewController()
        let users: UsersManager = services.get()
        let user = users.firstUser!
        let coordinator = SettingsPrivacyCoordinator(dest: vc, vm: SettingsPrivacyViewModelImpl(user: user), services: self.services)
        coordinator?.start()
        self.viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}

