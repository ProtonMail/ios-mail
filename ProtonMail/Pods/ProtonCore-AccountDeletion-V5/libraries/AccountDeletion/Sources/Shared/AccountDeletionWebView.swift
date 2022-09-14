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

import WebKit
#if canImport(ProtonCore_UIFoundations)
import ProtonCore_UIFoundations
#else
import PMUIFoundations
#endif
#if canImport(ProtonCore_Log)
import ProtonCore_Log
#else
import PMLog
#endif
#if canImport(ProtonCore_Foundations)
import ProtonCore_Foundations
#endif
#if canImport(ProtonCore_Networking)
import ProtonCore_Networking
#else
import PMCommon
#endif
#if canImport(ProtonCore_Services)
import ProtonCore_Services
#endif

final class WeaklyProxingScriptHandler<OtherHandler: WKScriptMessageHandler>: NSObject, WKScriptMessageHandler {
    private weak var otherHandler: OtherHandler?
    
    init(_ otherHandler: OtherHandler) { self.otherHandler = otherHandler }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let otherHandler = otherHandler else { return }
        otherHandler.userContentController(userContentController, didReceive: message)
    }
}

// swiftlint:disable:next class_delegate_protocol
public protocol AccountDeletionWebViewDelegate {
    func shouldCloseWebView(_ viewController: AccountDeletionViewController, completion: @escaping () -> Void)
}

final class AccountDeletionWebView: AccountDeletionViewController {
    
    #if canImport(UIKit)
    var banner: PMBanner?
    var loader = UIActivityIndicatorView()
    #endif
    
    #if canImport(AppKit)
    var loader = NSProgressIndicator()
    #endif
    
    // swiftlint:disable weak_delegate
    /// The delegate is being kept strongly so that the client doesn't have to care
    /// about keeping some object to receive the completion block.
    var stronglyKeptDelegate: AccountDeletionWebViewDelegate?
    let userContentController = WKUserContentController()
    let viewModel: AccountDeletionViewModelInterface
    var webView: WKWebView?
    
    init(viewModel: AccountDeletionViewModelInterface) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = configureUI()
        loadWebContent(webView: webView)
        self.webView = webView
        #if canImport(UIKit) && canImport(ProtonCore_Foundations)
        generateAccessibilityIdentifiers()
        #endif
    }
    
    private func configureUI() -> WKWebView {
        styleUI()
        
        userContentController.add(WeaklyProxingScriptHandler(self), name: "iOS")
        
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.userContentController = userContentController
        viewModel.setup(webViewConfiguration: webViewConfiguration)
        
        if #available(iOS 13.0, macOS 10.15, *) {
            webViewConfiguration.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        webViewConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        view.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11, macOS 11, *) {
            let layoutGuide = view.safeAreaLayoutGuide
            webView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        } else {
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
        
        view.addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        
        #if canImport(UIKit)
        if #available(iOS 13, *) {
            loader.style = .large
        }
        loader.centerInSuperview()
        loader.startAnimating()
        #endif
        
        #if canImport(AppKit)
        loader.style = .spinning
        loader.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loader.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loader.startAnimation(nil)
        #endif
        
        return webView
    }
    
    private var lastLoadingURL: String?
    
    private func loadWebContent(webView: WKWebView) {
        URLCache.shared.removeAllCachedResponses()
        let requestObj = viewModel.getURLRequest
        lastLoadingURL = requestObj.url?.absoluteString
        PMLog.debug("account deletion loading webview with url \(lastLoadingURL ?? "-")")
        #if canImport(AppKit)
        webView.customUserAgent = "ipad"
        #endif
        webView.load(requestObj)
    }
}

extension AccountDeletionWebView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
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
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadingError(webView, error: error)
    }
    
    func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        handleLoadingError(webView, error: error)
    }
    
    private func handleLoadingError(_ webView: WKWebView, error: Error) {
        PMLog.debug("webview load fail with error \(error)")
        guard let loadingURL = lastLoadingURL else { return }
        viewModel.shouldRetryFailedLoading(host: loadingURL, error: error) { [weak self] in
            switch $0 {
            case .dontRetry: self?.onAccountDeletionAppFailure(message: error.localizedDescription)
            case .retry: self?.loadWebContent(webView: webView)
            case .apiMightBeBlocked(let message): self?.apiMightBeBlockedFailure(message: message, originalError: error)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PMLog.debug("webview did finish navigation")
    }
}

extension AccountDeletionWebView: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        
        openUrl(url)
        
        configuration.userContentController = userContentController
        return WKWebView(frame: webView.frame, configuration: configuration)
    }
}

extension AccountDeletionWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "iOS" else { return }
        viewModel.interpretMessage(message) { [weak self] in
            self?.presentSuccessfulLoading()
        } notificationPresentation: { [weak self] notificationType, notificationMessage in
            self?.presentNotification(type: notificationType, message: notificationMessage)
        } successPresentation: { [weak self] in
            self?.presentSuccessfulAccountDeletion()
        } closeWebView: { [weak self] completion in
            guard let self = self else { return }
            self.stronglyKeptDelegate?.shouldCloseWebView(self, completion: completion)
        }
    }
    
    func onAccountDeletionAppFailure(message: String) {
        let viewModel = self.viewModel
        self.stronglyKeptDelegate?.shouldCloseWebView(self, completion: {
            viewModel.deleteAccountDidErrorOut(message: message)
        })
    }
    
    func apiMightBeBlockedFailure(message: String, originalError: Error) {
        let viewModel = self.viewModel
        self.stronglyKeptDelegate?.shouldCloseWebView(self, completion: {
            viewModel.deleteAccountFailedBecauseApiMightBeBlocked(message: message, originalError: originalError)
        })
    }
}

#if canImport(UIKit) && canImport(ProtonCore_Foundations)
extension AccountDeletionWebView: AccessibleView {}
#endif
