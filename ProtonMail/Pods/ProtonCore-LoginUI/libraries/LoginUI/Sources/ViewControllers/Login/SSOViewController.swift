//
//  SSOViewController.swift
//  ProtonCore-Login - Created on 15/06/2023.
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

import WebKit
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import ProtonCoreObservability

final class SSOViewController: UIViewController, AccessibleView {
    var webView: WKWebView?
    var activityIndicator: UIActivityIndicatorView?

    weak var webViewDelegate: WKNavigationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        configureUI()
        generateAccessibilityIdentifiers()
        view.accessibilityIdentifier = "SSOViewController"
        activityIndicator?.startAnimating()
    }

    private func configureUI() {
        let activityIndicator = UIActivityIndicatorView(frame: .zero)
        activityIndicator.color = .gray
        self.activityIndicator = activityIndicator
        activityIndicator.hidesWhenStopped = true
        view.addSubviews(activityIndicator)
        activityIndicator.addConstraints {
            [
                $0.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                $0.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        }
        let closeBarButtonItem = UIBarButtonItem(image: IconProvider.cross, style: .plain, target: self, action: #selector(closeWebView))
        closeBarButtonItem.tintColor = ColorProvider.IconNorm
        closeBarButtonItem.accessibilityLabel = "closeButton"
        navigationItem.leftBarButtonItem = closeBarButtonItem
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.bringSubviewToFront(activityIndicator)
    }

    @objc private func closeWebView() {
        ObservabilityEnv.report(.ssoIdentityProviderLoginResult(status: .canceled))
        dismiss(animated: true)
    }

    private func setupWebView() {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        webViewConfiguration.defaultWebpagePreferences.preferredContentMode = .mobile
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = webViewDelegate
        view.addSubview(webView)
        let layoutGuide = view.safeAreaLayoutGuide
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        self.webView = webView
    }

    func loadRequest(request: URLRequest) {
        activityIndicator?.stopAnimating()
        webView?.load(request)
    }
}

#endif
