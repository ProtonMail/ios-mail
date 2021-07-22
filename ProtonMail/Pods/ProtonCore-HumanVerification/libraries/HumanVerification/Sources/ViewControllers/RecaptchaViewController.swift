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
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations
import ProtonCore_Foundations

class RecaptchaViewController: UIViewController, AccessibleView {

    // MARK: Outlets

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var verifyingLabel: UILabel!

    private var startVerify: Bool = false
    private var finalToken: String?

    var viewModel: RecaptchaViewModel!

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
        webView.scrollView.isScrollEnabled = UIDevice.current.isSmallIphone
        stackView.isHidden = true
        loadNewCaptcha()
        verifyingLabel.text = CoreString._hv_verification_verifying_button
    }

    private func loadNewCaptcha() {
        URLCache.shared.removeAllCachedResponses()
        let requestObj = URLRequest(url: viewModel.getCaptchaURL())
        webView.loadRequest(requestObj)
    }

    private func checkCaptcha() {
        guard let finalToken = finalToken else { return }
        stackView.isHidden = false
        viewModel.finalToken(token: finalToken, complete: { res, error, finish in
            DispatchQueue.main.async {
                self.stackView.isHidden = true
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

// MARK: - UIWebViewDelegate

extension RecaptchaViewController: UIWebViewDelegate {

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let urlString = request.url?.absoluteString else { return true }

        if viewModel.isStartVerifyPattern(urlString: urlString) {
            startVerify = true
        }

        if viewModel.isResultFalsePattern(urlString: urlString) {
            return false
        }

        if viewModel.isExpiredRecaptchaRes(urlString: urlString) {
            webView.reload()
            return false
        } else if viewModel.isRecaptchaRes(urlString: urlString) {
            self.finalToken = viewModel.getFinalToken(urlString: urlString)
            checkCaptcha()
            return false
        }
        return true
    }
}

#endif
