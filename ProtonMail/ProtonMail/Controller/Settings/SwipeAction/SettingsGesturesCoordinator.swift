//
//  SettingsGesturesCoordinator.swift
//  ProtonMail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class SettingsGesturesCoordinator {
    internal weak var viewController: SettingsGesturesViewController?

    private weak var navigationController: UINavigationController?

    enum Destination: String {
        case actionSelection
    }

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = SettingsGestureViewModelImpl(cache: userCachedStatus)
        let viewController = SettingsGesturesViewController(viewModel: viewModel, coordinator: self)

        self.viewController = viewController

        let navigation = UINavigationController(rootViewController: viewController)
        self.navigationController?.present(navigation, animated: true, completion: nil)
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
