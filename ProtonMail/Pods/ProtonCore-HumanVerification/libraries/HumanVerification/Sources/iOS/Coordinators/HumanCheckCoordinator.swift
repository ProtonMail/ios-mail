//
//  HumanCheckCoordinator.swift
//  ProtonCore-HumanVerification - Created on 8/20/19.
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

import UIKit
import enum ProtonCoreDataModel.ClientApp
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreFoundations

class HumanCheckCoordinator {

    // MARK: - Private properties

    private let apiService: APIService
    private let clientApp: ClientApp
    private var destination: String = ""
    private var title: String?
    private let inAppTheme: () -> InAppTheme

    /// View controllers
    private let rootViewController: UIViewController?
    private let isModalPresentation: Bool
    private var initialViewController: HumanVerifyViewController?
    private var initialHelpViewController: HVHelpViewController?

    /// View models
    let humanVerifyViewModel: HumanVerifyViewModel

    // MARK: - Public properties

    weak var delegate: HumanCheckMenuCoordinatorDelegate?

    // MARK: - Public methods

    init(rootViewController: UIViewController?, isModalPresentation: Bool = true, apiService: APIService, parameters: HumanVerifyParameters, inAppTheme: @escaping () -> InAppTheme, clientApp: ClientApp) {
        self.rootViewController = rootViewController
        self.isModalPresentation = isModalPresentation
        self.apiService = apiService
        self.clientApp = clientApp
        self.title = parameters.title
        self.inAppTheme = inAppTheme

        self.humanVerifyViewModel = HumanVerifyViewModel(api: apiService, startToken: parameters.startToken, methods: parameters.methods, clientApp: clientApp)
        self.humanVerifyViewModel.onVerificationCodeBlock = { [weak self] verificationCodeBlock in
            guard let self = self else { return }
            self.delegate?.verificationCode(tokenType: self.humanVerifyViewModel.getToken(), verificationCodeBlock: verificationCodeBlock)
        }

        if NSClassFromString("XCTest") == nil {
            if parameters.methods.count == 0 {
                self.initialHelpViewController = getHelpViewController
            } else {
                instantiateViewController()
            }
        }
    }

    func start() {
        showHumanVerification()
    }

    // MARK: - Private methods

    private func instantiateViewController() {
        initialViewController = instantiateVC(method: HumanVerifyViewController.self, identifier: "HumanVerifyViewController", inAppTheme: inAppTheme)
        initialViewController?.viewModel = humanVerifyViewModel
        initialViewController?.delegate = self
        initialViewController?.isModalPresentation = isModalPresentation
        initialViewController?.viewTitle = title
    }

    private func showHumanVerification() {
        guard let viewController = self.initialHelpViewController ?? self.initialViewController else { return }
        if let rootViewController = rootViewController {
            let nav = DarkModeAwareNavigationViewController()
            nav.modalPresentationStyle = .fullScreen
            nav.viewControllers = [viewController]
            nav.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
            if isModalPresentation {
                nav.hideBackground()
                rootViewController.present(nav, animated: true)
            } else {
                rootViewController.show(viewController, sender: nil)
            }
        } else {
            var topViewController: UIViewController?
            let keyWindow = UIApplication.firstKeyWindow
            if var top = keyWindow?.rootViewController {
                while let presentedViewController = top.presentedViewController {
                    top = presentedViewController
                }
                topViewController = top
            }
            let nav = DarkModeAwareNavigationViewController()
            nav.modalPresentationStyle = .fullScreen
            nav.viewControllers = [viewController]
            nav.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
            if isModalPresentation {
                nav.hideBackground()
                topViewController?.present(nav, animated: true)
            } else {
                topViewController?.show(viewController, sender: nil)
            }
        }
    }

    private func showHelp() {
        initialViewController?.navigationController?.pushViewController(getHelpViewController, animated: true)
    }

    private var getHelpViewController: HVHelpViewController {
        let helpViewController = instantiateVC(method: HVHelpViewController.self, identifier: "HumanCheckHelpViewController", inAppTheme: inAppTheme)
        helpViewController.delegate = self
        helpViewController.viewModel = HelpViewModel(url: apiService.humanDelegate?.getSupportURL(), clientApp: clientApp)
        return helpViewController
    }
}

// MARK: - HumanVerifyViewControllerDelegate

extension HumanCheckCoordinator: HumanVerifyViewControllerDelegate {
    func didFinishViewController() {
        if isModalPresentation {
            initialViewController?.navigationController?.dismiss(animated: true)
        }
    }

    func willReopenViewController() {
        close()
        instantiateViewController()
        showHumanVerification()
    }

    func didDismissViewController() {
        close()
        delegate?.close()
    }

    func didDismissWithError(code: Int, description: String) {
        close()
        delegate?.closeWithError(code: code, description: description)
    }

    func emailAddressAlreadyTakenWithError(code: Int, description: String) {
        delegate?.closeWithError(code: code, description: description)
    }

    func didShowHelpViewController() {
        showHelp()
    }

    private func close() {
        if isModalPresentation {
            initialViewController?.navigationController?.dismiss(animated: true)
        } else {
            initialViewController?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - HVHelpViewControllerDelegate

extension HumanCheckCoordinator: HVHelpViewControllerDelegate {
    func didDismissHelpViewController() {
        if self.initialHelpViewController != nil {
            initialHelpViewController?.dismiss(animated: true)
            delegate?.close()
        } else {
            initialViewController?.navigationController?.popViewController(animated: true)
        }
    }
}

extension HumanCheckCoordinator {
    private func instantiateVC<T: UIViewController>(
        method: T.Type, identifier: String, inAppTheme: () -> InAppTheme
    ) -> T {
        let storyboard = UIStoryboard.init(name: "HumanVerify", bundle: HVCommon.bundle)
        let customViewController = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        customViewController.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
        return customViewController
    }
}

#endif
