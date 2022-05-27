//
//  LabelManagerCoordinator.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import Foundation
final class LabelManagerCoordinator: DefaultCoordinator, CoordinatorDismissalObserver {
    var services: ServiceFactory

    typealias VC = LabelManagerViewController

    weak var viewController: VC?
    private weak var viewModel: LabelManagerProtocol?
    var pendingActionAfterDismissal: (() -> Void)?

    init(services: ServiceFactory,
         viewController: LabelManagerViewController,
         viewModel: LabelManagerProtocol) {
        self.services = services
        self.viewController = viewController
        self.viewModel = viewModel
    }

    func start() {
        guard let viewController = self.viewController,
              let viewModel = self.viewModel else { return }
        viewController.set(viewModel: viewModel, coordinator: self)
        viewModel.set(uiDelegate: viewController)
    }

    func goToEditing(label: MenuLabel?) {
        guard let user = self.viewModel?.user,
              let type = self.viewModel?.type,
              let data = self.viewModel?.data else { return }
        let labelVM = LabelEditViewModel(user: user, label: label, type: type, labels: data)
        let labelVC = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: self.services,
                                               viewController: labelVC,
                                               viewModel: labelVM,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        guard let nvc = labelVC.navigationController else { return }
        self.viewController?.navigationController?.present(nvc, animated: true, completion: nil)
    }
}
