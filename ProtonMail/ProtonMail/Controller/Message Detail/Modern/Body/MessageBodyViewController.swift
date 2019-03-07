//
//  MessageBodyViewController.swift
//  ProtonMail - Created on 07/03/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import UIKit

class MessageBodyViewController: UIViewController {
    private var webView: WKWebView!
    private var coordinator: MessageBodyCoordinator!
    private var viewModel: MessageBodyViewModel!
    
    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader()
        } else {
            return HTMLStringSecureLoader()
        }
    }()
    
    deinit {
        self.loader.eject(from: self.webView.configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        self.loader.inject(into: config)
        if #available(iOS 10.0, *) {
            config.dataDetectorTypes = .pm_email
            config.ignoresViewportScaleLimits = true
        }
        
        // oh, WKWebView is available in IB since iOS 11 only
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        
        self.view.addSubview(self.webView)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loader.load(contents: self.viewModel.contents, in: webView)
    }
}

extension MessageBodyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.viewModel.contentsHeight = self.webView?.scrollView.contentSize.height ?? 0
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // nothing
    }
}

extension MessageBodyViewController: ViewModelProtocol {
    func set(viewModel: MessageBodyViewModel) {
        self.viewModel = viewModel
    }
}

extension MessageBodyViewController: CoordinatedNew {
    func set(coordinator: MessageBodyCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
}
