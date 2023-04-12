//
//  CreateAddressCoordinator.swift
//  ProtonCore-Login - Created on 30.11.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import ProtonCore_UIFoundations
import ProtonCore_Login
import ProtonCore_FeatureSwitch

protocol CreateAddressCoordinatorDelegate: AnyObject {
    func createAddressCoordinatorDidFinish(endLoading: @escaping () -> Void, createAddressCoordinator: CreateAddressCoordinator, data: LoginData)
}

final class CreateAddressCoordinator {

    // MARK: - Properties

    private let navigationController: LoginNavigationViewController
    private let container: Container
    private let externalLinks: ExternalLinks

    private let data: CreateAddressData
    private let customErrorPresenter: LoginErrorPresenter?
    private let defaultUsername: String?

    weak var delegate: CreateAddressCoordinatorDelegate?

    init(container: Container,
         navigationController: LoginNavigationViewController,
         data: CreateAddressData,
         customErrorPresenter: LoginErrorPresenter?,
         defaultUsername: String?) {
        self.container = container
        self.navigationController = navigationController
        self.data = data
        self.customErrorPresenter = customErrorPresenter
        self.defaultUsername = defaultUsername
        externalLinks = container.makeExternalLinks()
    }

    func start() {
        showCreateAddress()
    }

    // MARK: - Actions

    private func showCreateAddress() {
        let createAddressViewController = UIStoryboard.instantiate(CreateAddressViewController.self)
        createAddressViewController.viewModel = container.makeCreateAddressViewModel(data: data, defaultUsername: defaultUsername)
        createAddressViewController.customErrorPresenter = customErrorPresenter
        createAddressViewController.delegate = self
        createAddressViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()
            
            self.container.troubleShootingHelper.showTroubleShooting(over: self.navigationController)
        }
        navigationController.pushViewController(createAddressViewController, animated: true)
    }
}

// MARK: - Navigation delegate

extension CreateAddressCoordinator: NavigationDelegate {
    func userDidGoBack() {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - Choose username VC delegate

extension CreateAddressCoordinator: CreateAddressViewControllerDelegate {
    func userDidFinishCreatingAddress(endLoading: @escaping () -> Void, data: LoginData) {
        delegate?.createAddressCoordinatorDidFinish(endLoading: endLoading, createAddressCoordinator: self, data: data)
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMLogin", controllerType: controllerType)
    }
}
