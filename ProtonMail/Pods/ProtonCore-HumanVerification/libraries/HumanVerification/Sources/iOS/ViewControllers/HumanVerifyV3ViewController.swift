//
//  EmailVerifyViewController.swift
//  ProtonCore-HumanVerification - Created on 2/1/16.
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
import ProtonCore_UIFoundations
import ProtonCore_Foundations
import ProtonCore_Networking
import ProtonCore_Services

protocol HumanVerifyV3ViewControllerDelegate: AnyObject {
    func didDismissViewController()
    func didShowHelpViewController()
    func willReopenViewController()
    func didFinishViewController()
    func didEditEmailAddress()
}

final class HumanVerifyV3ViewController: UIViewController, AccessibleView {
    
    // MARK: Outlets

    var webView: WKWebView!
    @IBOutlet weak var helpBarButtonItem: UIBarButtonItem! {
        didSet {
            helpBarButtonItem.title = CoreString._hv_help_button
            helpBarButtonItem.tintColor = ColorProvider.BrandNorm
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.color = ColorProvider.IconNorm
        }
    }

    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!

    // MARK: Properties
    private let userContentController = WKUserContentController()
    weak var delegate: HumanVerifyV3ViewControllerDelegate?
    var viewModel: HumanVerifyV3ViewModel!
    var isModalPresentation = true
    var banner: PMBanner?
    @available(iOS 12.0, *)
    lazy var currentInterfaceStyle: UIUserInterfaceStyle = .unspecified
    
    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        configureUI()
        loadWebContent()
        generateAccessibilityIdentifiers()
    }
    
    deinit {
        userContentController.removeAllUserScripts()
        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            if UIApplication.shared.applicationState == .active {
                checkInterfaceStyle()
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func closeAction(_ sender: Any) {
        delegate?.didDismissViewController()
    }
    
    @IBAction func helpAction(_ sender: Any) {
        delegate?.didShowHelpViewController()
    }
    
    // MARK: Private interface

    private func configureUI() {
        title = CoreString._hv_title
        if #available(iOS 12.0, *) {
            currentInterfaceStyle = traitCollection.userInterfaceStyle
        }
        closeBarButtonItem.tintColor = ColorProvider.IconNorm
        closeBarButtonItem.accessibilityLabel = "closeButton"
        updateTitleAttributes()
        view.backgroundColor = ColorProvider.BackgroundNorm
        activityIndicator?.startAnimating()
        closeBarButtonItem.image = isModalPresentation ? UIImage.closeImage : UIImage.backImage
        setupWebView()
    }
    
    private func setupWebView() {
        userContentController.add(WeaklyProxingScriptHandler(self), name: viewModel.scriptName)
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.userContentController = userContentController
        viewModel.setup(webViewConfiguration: webViewConfiguration)
        if #available(iOS 13.0, *) {
            webViewConfiguration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        webViewConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.isHidden = true
        view.addSubview(webView)
        view.bringSubviewToFront(activityIndicator)
        
        let layoutGuide = view.safeAreaLayoutGuide
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
    }
    
    private var lastLoadingURL: String?

    private func loadWebContent() {
        URLCache.shared.removeAllCachedResponses()
        let requestObj = viewModel.getURLRequest
        lastLoadingURL = requestObj.url?.absoluteString
        webView.load(requestObj)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            if #available(iOS 12.0, *) {
                self?.checkInterfaceStyle()
            }
        }
    }

    @available(iOS 12.0, *)
    private func checkInterfaceStyle() {
        if traitCollection.userInterfaceStyle != currentInterfaceStyle {
            loadWebContent()
            currentInterfaceStyle = traitCollection.userInterfaceStyle
        }
    }
}

// MARK: - WKWebViewDelegate

extension HumanVerifyV3ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        enableUserInteraction(for: webView)
        decisionHandler(.allow)
    }

    func webView(_ webview: WKWebView, didCommit nav: WKNavigation!) {
        enableUserInteraction(for: webView)
        activityIndicator?.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleFailedRequest(webView, error)
    }

    func webView(_ webview: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        handleFailedRequest(webView, error)
    }
    
    private func handleFailedRequest(_ webview: WKWebView, _ error: Error) {
        hideActivityIndicator()
        guard let loadingUrl = lastLoadingURL else { return }
        viewModel.shouldRetryFailedLoading(host: loadingUrl, error: error) { [weak self] in
            if $0 {
                self?.loadWebContent()
            } else {
                // present error, CP-3101
            }
        }
    }

    private func hideActivityIndicator() {
        enableUserInteraction(for: webView)
        webView.isHidden = false
        activityIndicator?.stopAnimating()
    }

    private func enableUserInteraction(for webView: WKWebView) {
        webView.window?.isUserInteractionEnabled = true
    }
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleAuthenticationChallenge(
            didReceive: challenge,
            noTrustKit: PMAPIService.noTrustKit,
            trustKit: PMAPIService.trustKit,
            challengeCompletionHandler: completionHandler
        )
    }
}

extension HumanVerifyV3ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        UIApplication.openURLIfPossible(url)
        return WKWebView(frame: webView.frame, configuration: configuration)
    }
}

extension HumanVerifyV3ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        viewModel.interpretMessage(message: message, notificationMessage: { type, message in
            DispatchQueue.main.async { [weak self] in
                if let self = self {
                    switch type {
                    case .success:
                        self.banner?.dismiss()
                        self.banner = PMBanner(message: message, style: PMBannerNewStyle.success)
                        self.banner?.show(at: .topCustom(.baner), on: self)
                    case .error:
                        self.banner?.dismiss()
                        self.banner = PMBanner(message: message, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
                        self.banner?.addButton(text: CoreString._hv_ok_button) { [weak self] _ in
                            self?.banner?.dismiss()
                        }
                        self.banner?.show(at: .top, on: self)
                    default:
                        break
                    }
                }
            }
        }, arrivedMessage: { type in
            switch type {
            case .loaded:
                DispatchQueue.main.async { [weak self] in
                    self?.hideActivityIndicator()
                }
            case .close:
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didEditEmailAddress()
                }
            }
        }, errorHandler: { _ in
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.willReopenViewController()
            }
        }, completeHandler: { method in
            let delay: TimeInterval = method.predefinedMethod == .captcha ? 1.0 : 0.0
            // for captcha method there is an additional artificial delay to see verification animation
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.delegate?.didFinishViewController()
            }
        })
    }
}
