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

protocol CreateAddressCoordinatorDelegate: AnyObject {
    func createAddressCoordinatorDidFinish(endLoading: @escaping () -> Void, createAddressCoordinator: CreateAddressCoordinator, data: LoginData)
}

final class CreateAddressCoordinator {

    // MARK: - Properties

    private let navigationController: LoginNavigationViewController
    private let container: Container
    private let externalLinks: ExternalLinks

    // data is mutable because it can change during the address creation process and we need to keep it updated. see CreateAddressViewModel
    private var data: CreateAddressData
    private let customErrorPresenter: LoginErrorPresenter?

    weak var delegate: CreateAddressCoordinatorDelegate?

    init(container: Container,
         navigationController: LoginNavigationViewController,
         data: CreateAddressData,
         customErrorPresenter: LoginErrorPresenter?) {
        self.container = container
        self.navigationController = navigationController
        self.data = data
        self.customErrorPresenter = customErrorPresenter
        externalLinks = container.makeExternalLinks()
    }

    func start() {
        showChooseUsername()
    }

    // MARK: - Actions

    private func showChooseUsername() {
        let chooseUsernameViewController = UIStoryboard.instantiate(ChooseUsernameViewController.self)
        chooseUsernameViewController.viewModel = container.makeChooseUsernameViewModel(data: data)
        chooseUsernameViewController.customErrorPresenter = customErrorPresenter
        chooseUsernameViewController.delegate = self
        chooseUsernameViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()
            
            self.container.troubleShootingHelper.showTroubleShooting(over: self.navigationController)
        }
        navigationController.pushViewController(chooseUsernameViewController, animated: true)
    }

    private func showCreateAddress(username: String) {
        let createAddressViewController = UIStoryboard.instantiate(CreateAddressViewController.self)
        createAddressViewController.viewModel = container.makeCreateAddressViewModel(
            username: username, data: data, updateUser: { [weak self] in
                guard let self = self else { return }
                self.data = self.data.withUpdatedUser($0)
            }
        )
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
    func userDidRequestGoBack() {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - Choose username VC delegate

extension CreateAddressCoordinator: ChooseUsernameViewControllerDelegate {
    func userDidFinishChoosingUsername(username: String) {
        showCreateAddress(username: username)
    }
}

// MARK: - Create Address VC delegate

extension CreateAddressCoordinator: CreateAddressViewControllerDelegate {
    func userDidRequestTermsAndConditions() {
        UIApplication.openURLIfPossible(externalLinks.termsAndConditions)
    }

    func userDidFinishCreatingAddress(endLoading: @escaping () -> Void, data: LoginData) {
        delegate?.createAddressCoordinatorDidFinish(endLoading: endLoading, createAddressCoordinator: self, data: data)
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMLogin", controllerType: controllerType)
    }
}
