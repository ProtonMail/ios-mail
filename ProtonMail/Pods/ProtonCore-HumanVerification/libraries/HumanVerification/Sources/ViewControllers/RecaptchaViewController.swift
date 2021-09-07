//
//  RecaptchaViewController.swift
//  ProtonCore-HumanVerification - Created on 12/17/15.
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

#if canImport(UIKit)
import UIKit
import WebKit
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations
import ProtonCore_Foundations

class RecaptchaViewController: UIViewController, AccessibleView {

    // MARK: Outlets

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var verifyingLabel: UILabel!

    private var startVerify: Bool = false
    private var finalToken: String?

    var viewModel: RecaptchaViewModel!
    
    private enum WaitingIndicatorState {
        case off
        case waiting
        case verifying
    }

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        generateAccessibilityIdentifiers()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    // MARK: Private interface

    private func configureUI() {
        view.backgroundColor = UIColorManager.BackgroundNorm
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = UIDevice.current.isSmallIphone
        setWaitingIndicatorState(state: .waiting)
        loadNewCaptcha()
        verifyingLabel.text = CoreString._hv_verification_verifying_button
    }
    
    private func setWaitingIndicatorState(state: WaitingIndicatorState) {
        switch state {
        case .off:
            activityIndicator?.stopAnimating()
            verifyingLabel.isHidden = true
        case .waiting:
            activityIndicator?.startAnimating()
            verifyingLabel.isHidden = true
        case .verifying:
            activityIndicator?.startAnimating()
            verifyingLabel.isHidden = false
        }
    }

    private func loadNewCaptcha() {
        URLCache.shared.removeAllCachedResponses()
        let requestObj = URLRequest(url: viewModel.getCaptchaURL())
        webView.load(requestObj)
    }

    private func checkCaptcha() {
        guard let finalToken = finalToken else { return }
        setWaitingIndicatorState(state: .verifying)
        viewModel.finalToken(token: finalToken, complete: { res, error, finish in
            DispatchQueue.main.async {
                self.setWaitingIndicatorState(state: .off)
                if res {
                    self.navigationController?.dismiss(animated: true) {
                        finish?()
                    }
                } else {
                    if let error = error {
                        let banner = PMBanner(message: error.localizedDescription, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
                        banner.addButton(text: CoreString._hv_ok_button) { _ in
                            banner.dismiss()
                            self.loadNewCaptcha()
                        }
                        banner.show(at: .topCustom(.baner), on: self)
                    }
                }
            }
        })
    }
}

// MARK: - WKWebViewDelegate

extension RecaptchaViewController: WKNavigationDelegate {

    // old webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType: WKWebView.NavigationType)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        enableUserInteraction(for: webView)

        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }

        if viewModel.isStartVerifyPattern(urlString: urlString) {
            startVerify = true
        }

        if viewModel.isResultFalsePattern(urlString: urlString) {
            decisionHandler(.cancel)
            return
        }

        if viewModel.isExpiredRecaptchaRes(urlString: urlString) {
            webView.reload()
            decisionHandler(.cancel)
            return
        } else if viewModel.isRecaptchaRes(urlString: urlString) {
            self.finalToken = viewModel.getFinalToken(urlString: urlString)
            checkCaptcha()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
        return
    }

    func webView(_ webview: WKWebView, didFinish nav: WKNavigation!) {
        enableUserInteraction(for: webView)
        setWaitingIndicatorState(state: .off)
    }

    func webView(_ webview: WKWebView, didCommit nav: WKNavigation!) {
        enableUserInteraction(for: webView)
        setWaitingIndicatorState(state: .waiting)
    }

    func webView(_ webview: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        enableUserInteraction(for: webView)
        setWaitingIndicatorState(state: .off)
    }

    private func enableUserInteraction(for webView: WKWebView) {
        webView.window?.isUserInteractionEnabled = true
    }
}

#endif
