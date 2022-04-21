//
//  LabelEditCoordinator.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

protocol CoordinatorDismissalObserver: AnyObject {
    var pendingActionAfterDismissal: (() -> Void)? { get set }

    func labelEditCoordinatorDidDismiss()
}

extension CoordinatorDismissalObserver {
    func labelEditCoordinatorDidDismiss() {
        pendingActionAfterDismissal?()
        pendingActionAfterDismissal = nil
    }
}

final class LabelEditCoordinator: DefaultCoordinator {
    var services: ServiceFactory

    typealias VC = LabelEditViewController

    weak var viewController: VC?
    private weak var viewModel: LabelEditVMProtocol?
    private weak var coordinatorDismissalObserver: CoordinatorDismissalObserver?

    init(services: ServiceFactory,
         viewController: LabelEditViewController,
         viewModel: LabelEditVMProtocol,
         coordinatorDismissalObserver: CoordinatorDismissalObserver) {
        self.services = services
        self.viewController = viewController
        self.viewModel = viewModel
        self.coordinatorDismissalObserver = coordinatorDismissalObserver
    }

    func start() {
        guard let viewController = self.viewController,
              let viewModel = self.viewModel else { return }
        viewController.set(viewModel: viewModel, coordinator: self)
        viewModel.set(uiDelegate: viewController)
    }

    func goToParentSelect() {
        guard let viewModel = self.viewModel else { return }
        let isInherit = viewModel.user.userinfo.inheritParentFolderColor == 1 ? true: false
        let useFolderColor = viewModel.user.userinfo.enableFolderColor == 1 ? true: false
        let parentVm = LabelParentSelectVM(labels: viewModel.labels,
                                           label: viewModel.label,
                                           useFolderColor: useFolderColor,
                                           inheritParentColor: isInherit,
                                           delegate: self,
                                           parentID: viewModel.parentID?.rawValue ?? "")
        let parentVC = LabelParentSelectViewController.instance(hasNavigation: false)
        parentVC.set(viewModel: parentVm)
        self.viewController?.navigationController?.show(parentVC, sender: nil)
    }

    func viewControllerDidDismiss() {
        coordinatorDismissalObserver?.labelEditCoordinatorDidDismiss()
    }
}

extension LabelEditCoordinator: LabelParentSelectDelegate {
    func select(parentID: String) {
        self.viewModel?.update(parentID: LabelID(parentID))
    }
}
