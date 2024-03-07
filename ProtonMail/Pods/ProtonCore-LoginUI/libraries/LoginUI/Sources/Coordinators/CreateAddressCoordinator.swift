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

#if os(iOS)

import Foundation
import UIKit
import ProtonCoreUIFoundations
import ProtonCoreLogin

protocol CreateAddressCoordinatorDelegate: AnyObject {
    func userDidGoBack()
    func createAddressCoordinatorDidFinish(endLoading: @escaping () -> Void, createAddressCoordinator: CreateAddressCoordinator, data: LoginData)
}

final class CreateAddressCoordinator {

    // MARK: - Properties

    private let navigationController: LoginNavigationViewController
    private let container: Container
    private let externalLinks: ExternalLinks

    private let data: CreateAddressData
    private let customization: LoginCustomizationOptions
    private let defaultUsername: String?

    weak var delegate: CreateAddressCoordinatorDelegate?

    init(container: Container,
         navigationController: LoginNavigationViewController,
         data: CreateAddressData,
         defaultUsername: String?,
         customization: LoginCustomizationOptions) {
        self.container = container
        self.navigationController = navigationController
        self.data = data
        self.customization = customization
        self.defaultUsername = defaultUsername
        externalLinks = container.makeExternalLinks()
    }

    func start() {
        showCreateAddress()
    }

    // MARK: - Actions

    private func showCreateAddress() {
        let createAddressViewController = UIStoryboard.instantiateInLogin(
            CreateAddressViewController.self, inAppTheme: customization.inAppTheme
        )
        createAddressViewController.viewModel = container.makeCreateAddressViewModel(data: data, defaultUsername: defaultUsername)
        createAddressViewController.customErrorPresenter = customization.customErrorPresenter
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
        delegate?.userDidGoBack()
    }
}

// MARK: - Choose username VC delegate

extension CreateAddressCoordinator: CreateAddressViewControllerDelegate {
    func userDidFinishCreatingAddress(endLoading: @escaping () -> Void, data: LoginData) {
        delegate?.createAddressCoordinatorDidFinish(endLoading: endLoading, createAddressCoordinator: self, data: data)
    }
}

#endif
