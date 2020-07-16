//
//  ComposeCoordinator.swift
//  ProtonMail - Created on 10/29/18.
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
class ComposeCoordinator : DefaultCoordinator {
    typealias VC = ComposeViewController

    weak var viewController: ComposeViewController?
    weak var navigationController: UINavigationController?
    
    let viewModel : ComposeViewModel
    var services: ServiceFactory
    
    init(vc: ComposeViewController, vm: ComposeViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    init(navigation: UINavigationController, vm: ComposeViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.navigationController = navigation
        self.services = services
        let rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: .composer)!
        let composer = rootViewController.children[0] as! ComposeViewController
        self.viewController = composer
    }
    
    weak var delegate: CoordinatorDelegate?

    enum Destination : String {
        case password          = "to_eo_password_segue"
        case expirationWarning = "expiration_warning_segue"
        case subSelection      = "toContactGroupSubSelection"
        case attachment        = "to_attachment"
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .password:
            guard let popup = destination as? ComposePasswordViewController else {
                return false
            }
            
            guard let vc = viewController else {
                return false
            }
            
            popup.pwdDelegate = self
            //get this data from view model
            popup.setupPasswords(vc.encryptionPassword, confirmPassword: vc.encryptionConfirmPassword, hint: vc.encryptionPasswordHint)
            
        case .expirationWarning:
            guard let popup = destination as? ExpirationWarningViewController else {
                return false
            }
            guard let vc = viewController else {
                return false
            }
            popup.delegate = self
            let nonePMEmail = vc.encryptionPassword.count <= 0 ? vc.headerView.nonePMEmails : [String]()
            popup.config(needPwd: nonePMEmail, pgp: vc.headerView.pgpEmails)
        case .subSelection:
            guard let destination = destination as? ContactGroupSubSelectionViewController else {
                return false
            }
            guard let vc = viewController else {
                return false
            }
            
            guard let group = vc.pickedGroup else {
                return false
            }
            destination.user = self.viewModel.getUser()
            destination.contactGroupName = group.contactTitle
            destination.selectedEmails = group.getSelectedEmailData()
            destination.callback = vc.pickedCallback
        case .attachment:
            guard let nav = destination as? UINavigationController else {
                return false
            }
            guard let destination = nav.viewControllers.first as? AttachmentsTableViewController else {
                return false
            }
            
            destination.delegate = viewController
            destination.message = viewModel.message
            
            break
        }
        return true
    }
    
    func start() {
        viewController?.set(viewModel: self.viewModel)
        viewController?.set(coordinator: self)
        
        if let navigation = self.navigationController, let vc = self.viewController {
            navigation.setViewControllers([vc], animated: true)
        }
    }
    
    func go(to dest: Destination) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: nil)
    }
}




extension ComposeCoordinator : ComposePasswordViewControllerDelegate {
    
    func Cancelled() {
        
    }
    
    func Apply(_ password: String, confirmPassword: String, hint: String) {
        guard let vc = viewController else {
            return
        }
        vc.encryptionPassword = password
        vc.encryptionConfirmPassword = confirmPassword
        vc.encryptionPasswordHint = hint
        vc.headerView.showEncryptionDone()
        vc.updateEO()
    }
    
    func Removed() {
        guard let vc = viewController else {
            return
        }
        vc.encryptionPassword = ""
        vc.encryptionConfirmPassword = ""
        vc.encryptionPasswordHint = ""
        
        vc.headerView.showEncryptionRemoved()
        vc.updateEO()
    }
}


extension ComposeCoordinator: ExpirationWarningVCDelegate{
    func send() {
        guard let vc = viewController else {
            return
        }
        vc.sendMessageStepTwo()
    }
    
    func learnMore() {
        #if !APP_EXTENSION
        UIApplication.shared.openURL(.eoLearnMore)
        #endif
    }
}
