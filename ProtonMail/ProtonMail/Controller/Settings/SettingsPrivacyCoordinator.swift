//
//  SettingsPrivacyCoordinator.swift
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

import UIKit

class SettingsPrivacyCoordinator: DefaultCoordinator {

    typealias VC = SettingsPrivacyViewController

    let viewModel: SettingsPrivacyViewModel
    var services: ServiceFactory

    internal weak var viewController: SettingsPrivacyViewController?
    internal weak var deepLink: DeepLink?

    lazy internal var configuration: ((SettingsPrivacyViewController) -> Void)? = { [unowned self] vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }

    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }

    enum Destination: String {
        case notification = "setting_notification"
    }

    init?(dest: UIViewController, vm: SettingsPrivacyViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
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
        }
        return false
    }
}
