//
//  SettingsGesturesCoordinator.swift
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

class SettingsGesturesCoordinator: DefaultCoordinator {
    typealias VC = SettingsGesturesViewController

    let viewModel: SettingsGestureViewModel
    var services: ServiceFactory

    internal weak var viewController: SettingsGesturesViewController?
    internal weak var deepLink: DeepLink?

    internal lazy var configuration: ((SettingsGesturesViewController) -> Void)? = { [unowned self] viewController in
        viewController.set(coordinator: self)
        viewController.set(viewModel: self.viewModel)
    }

    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }

    enum Destination: String {
        case actionSelection
    }

    init?(dest: UIViewController,
          viewModel: SettingsGestureViewModel,
          services: ServiceFactory,
          scene: AnyObject? = nil) {
        guard let next = dest as? VC else {
            return nil
        }
        self.viewController = next
        self.viewModel = viewModel
        self.services = services
    }

    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }

    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .actionSelection:
            guard let selectedAction = viewController?.selectedAction else {
                return
            }
            let viewController = SettingsSwipeActionSelectController()
            let viewModel = SettingsSwipeActionSelectViewModelImpl(cache: userCachedStatus,
                                                                   selectedAction: selectedAction)
            viewController.setModel(vm: viewModel)
            self.viewController?.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
