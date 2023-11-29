//
//  AccountDeletionWebView.swift
//  ProtonCore-AccountDeletion - Created on 10.12.21.
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
#if canImport(ProtonCoreUIFoundations)
import ProtonCoreUIFoundations
#else
import PMUIFoundations
#endif

import ProtonCoreNetworking

public typealias AccountDeletionViewController = UIViewController

public protocol AccountDeletionViewControllerPresenter {
    func present(_: UIViewController, animated: Bool, completion: (() -> Void)?)
}

extension UIViewController: AccountDeletionViewControllerPresenter {}

extension AccountDeletionService: AccountDeletion {
    
    public func initiateAccountDeletionProcess(
        over viewController: UIViewController,
        inAppTheme: @escaping () -> InAppTheme = { .default },
        performAfterShowingAccountDeletionScreen: @escaping () -> Void = { },
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void = { $0() },
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    ) {
        initiateAccountDeletionProcess(presenter: viewController,
                                       inAppTheme: inAppTheme,
                                       performAfterShowingAccountDeletionScreen: performAfterShowingAccountDeletionScreen,
                                       performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                                       completion: completion)
    }
}

extension AccountDeletionWebView {
    
    @objc func onBackButtonPressed() {
        let viewModel = self.viewModel
        self.navigationController?.presentingViewController?.dismiss(animated: true) {
            viewModel.deleteAccountWasClosed()
        }
    }
    
    func styleUI() {
        #if canImport(ProtonCoreUIFoundations)
        let backgroundColor: UIColor = ColorProvider.BackgroundNorm
        #else
        let backgroundColor: UIColor = UIColorManager.BackgroundNorm
        #endif
        view.backgroundColor = backgroundColor
        webView?.backgroundColor = backgroundColor
        webView?.scrollView.backgroundColor = backgroundColor
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) {
            webView?.underPageBackgroundColor = backgroundColor
        }
    }
    
    func presentSuccessfulLoading() {
        webView?.alpha = 0.0
        webView?.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.webView?.alpha = 1.0
        }
    }
    
    func presentSuccessfulAccountDeletion() {
        navigationItem.leftBarButtonItem = nil
        UIView.animate(withDuration: 1.0) { [weak self] in
            self?.webView?.alpha = 0.0
        } completion: { [weak self] _ in
            self?.webView?.isHidden = true
        }
        self.banner?.dismiss()
        self.banner = PMBanner(message: ADTranslation.delete_account_success.l10n,
                               style: PMBannerNewStyle.success,
                               dismissDuration: Double.infinity)
        self.banner?.show(at: .top, on: self)
    }
    
    func presentNotification(type: NotificationType, message: String) {
        self.banner?.dismiss()
        let style: PMBannerNewStyle
        switch type {
        case .error: style = .error
        case .warning: style = .warning
        case .info: style = .info
        case .success: style = .success
        }
        self.banner = PMBanner(message: message, style: style, dismissDuration: Double.infinity)
        self.banner?.addButton(text: ADTranslation.general_ok_action.l10n) { [weak self] _ in
            self?.banner?.dismiss()
        }
        self.banner?.show(at: .top, on: self)
    }
    
    func openUrl(_ url: URL) {
        #if canImport(ProtonCoreFoundations)
        UIApplication.openURLIfPossible(url)
        #else
        UIApplication.shared.openURL(url)
        #endif
    }
}

extension AccountDeletionService: AccountDeletionWebViewDelegate {
    
    public func shouldCloseWebView(_ viewController: AccountDeletionViewController, completion: @escaping () -> Void) {
        viewController.presentingViewController?.dismiss(animated: true, completion: completion)
    }
    
    func present(vc: AccountDeletionWebView,
                 over: AccountDeletionViewControllerPresenter,
                 inAppTheme: () -> InAppTheme,
                 completion: @escaping () -> Void) {
        let theme = inAppTheme().userInterfaceStyle
        vc.overrideUserInterfaceStyle = theme
        let navigationVC = DarkModeAwareNavigationViewController(rootViewController: vc)
        navigationVC.overrideUserInterfaceStyle = theme
        vc.title = ADTranslation.delete_account_title.l10n
        let leftBarButtonItem = UIBarButtonItem(
            image: IconProvider.arrowLeft,
            style: .done,
            target: vc,
            action: #selector(AccountDeletionWebView.onBackButtonPressed)
        )
        vc.navigationItem.leftBarButtonItem = leftBarButtonItem
        leftBarButtonItem.accessibilityIdentifier = "AccountDeletionWebViewController.leftBarButtonItem"
        #if canImport(ProtonCoreUIFoundations)
        let tintColor: UIColor = ColorProvider.IconNorm
        #else
        let tintColor: UIColor = UIColorManager.IconNorm
        #endif
        vc.navigationItem.leftBarButtonItem?.tintColor = tintColor
        navigationVC.setNavigationBarHidden(false, animated: false)
        navigationVC.modalPresentationStyle = .fullScreen
        over.present(navigationVC, animated: true, completion: completion)
    }
}

#endif
