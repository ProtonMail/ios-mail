//
//  SingleMessageCoordinator.swift
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

import UIKit

class SingleMessageCoordinator {

    weak var viewController: SingleMessageViewController?

    private let labelId: String
    private let message: Message
    private let user: UserManager
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController, labelId: String, message: Message, user: UserManager) {
        self.navigationController = navigationController
        self.labelId = labelId
        self.message = message
        self.user = user
    }

    func start() {
        let viewModel = SingleMessageViewModel(
            labelId: labelId,
            message: message,
            user: user,
            linkOpenerCache: userCachedStatus
        )
        let viewController = SingleMessageViewController(coordinator: self, viewModel: viewModel)
        self.viewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func navigate(to navigationAction: SingleMessageNavigationAction) {
        switch navigationAction {
        case .compose(let contact):
            presentCompose(with: contact)
        case .contacts(let contact):
            presentAddContacts(with: contact)
        }
    }

    private func presentCompose(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }

    private func presentAddContacts(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.contact.storyboard
        guard let destination = board.instantiateViewController(
                withIdentifier: "UINavigationController-d3P-H0-xNt") as? UINavigationController,
              let viewController = destination.viewControllers.first as? ContactEditViewController else {
            return
        }
        sharedVMService.contactAddViewModel(viewController, user: user, contactVO: contact)
        self.viewController?.present(destination, animated: true)
    }

}
