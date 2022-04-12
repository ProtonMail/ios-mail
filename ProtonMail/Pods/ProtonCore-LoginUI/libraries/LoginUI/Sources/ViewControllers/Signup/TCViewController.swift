//
//  TCViewController.swift
//  ProtonCore-Login - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit
import WebKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol TCViewControllerDelegate: AnyObject {
    func termsAndConditionsClose()
}

class TCViewController: UIViewController, AccessibleView {

    weak var delegate: TCViewControllerDelegate?
    var termsAndConditionsURL: URL?
    
    // MARK: Outlets

    @IBOutlet weak var webView: WKWebView!

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        navigationItem.title = CoreString._su_terms_conditions_view_title
        navigationController?.navigationBar.tintColor = ColorProvider.IconNorm
        setUpCloseButton(showCloseButton: true, action: #selector(TCViewController.onCloseButtonTap(_:)))
        setupWebView()
        generateAccessibilityIdentifiers()
        updateTitleAttributes()
    }

    // MARK: Actions

    @objc func onCloseButtonTap(_ sender: UIButton) {
        delegate?.termsAndConditionsClose()
    }

    // MARK: Private methods

    func setupWebView() {
        webView.navigationDelegate = self
        guard let url = self.termsAndConditionsURL else { return }
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20.0)
        webView.load(request)
    }
}

extension TCViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }

        // promise webview won't navigate to other link
        if url == termsAndConditionsURL?.absoluteString {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}
