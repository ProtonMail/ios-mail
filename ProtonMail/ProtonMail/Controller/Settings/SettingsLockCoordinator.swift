//
//  SettingsLockCoordinator.swift
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

class SettingsLockCoordinator : DefaultCoordinator {

    typealias VC = SettingsLockViewController
    
    let viewModel : SettingsLockViewModel
    var services: ServiceFactory
    
    internal weak var viewController: SettingsLockViewController?
    internal weak var deepLink: DeepLink?
    
    lazy internal var configuration: ((SettingsLockViewController) -> ())? = { [unowned self] vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }
    
    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }
    
    enum Destination : String {
        case pinCode         = "setting_setup_pingcode"
        case pinCodeSetup = "pincode_setup"
    }
    
    init?(dest: UIViewController, vm: SettingsLockViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
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
        case .pinCode:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        case .pinCodeSetup:
            let nav = UINavigationController()
            nav.modalPresentationStyle = .fullScreen
            let coordinator = PinCodeSetupCoordinator(nav: nav, services: self.services)
            coordinator.configuration = { vc in
                vc.viewModel = SetPinCodeModelImpl()
            }
            coordinator.start()
            self.viewController?.present(nav, animated: true, completion: nil)
        }
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .pinCode:
            guard let next = destination as? PinCodeViewController else {
                return false
            }
            next.viewModel = SetPinCodeModelImpl()
        case .pinCodeSetup:
            break
        }
        
        return true
    }
}

