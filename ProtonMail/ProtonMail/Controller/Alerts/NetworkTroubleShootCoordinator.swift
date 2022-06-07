//
//  NetworkTroubleShootCoordinator.swift
//  Proton Mail - Created on 3/01/2020.
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

class NetworkTroubleShootCoordinator: DefaultCoordinator {
    typealias VC = NetworkTroubleShootViewController

    weak var viewController: NetworkTroubleShootViewController?
    weak var navigationController: UINavigationController?

    let viewModel: NetworkTroubleShootViewModel
    var services: ServiceFactory

    init(segueNav: UINavigationController, vm: NetworkTroubleShootViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.navigationController = segueNav
        self.services = services
        self.viewController = segueNav.firstViewController() as? NetworkTroubleShootViewController
    }

    weak var delegate: CoordinatorDelegate?

    func start() {
        viewController?.set(viewModel: self.viewModel)
        viewController?.set(coordinator: self)
    }
}
