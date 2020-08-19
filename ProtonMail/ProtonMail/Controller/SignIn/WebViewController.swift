//
//  WebViewController.swift
//  ProtonMail - Created on 3/12/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

class WebViewController: UIViewController, ViewModelProtocol {
    typealias viewModelType = WebViewModel
    func set(viewModel: WebViewModel) {
        self.viewModel = viewModel
    }
    
    private var wkWebView: WKWebView!
    private var viewModel : WebViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupWebView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        self.wkWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.wkWebView.navigationDelegate = self
        self.wkWebView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.wkWebView)
        
        self.wkWebView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.wkWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.wkWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.wkWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        let url = self.viewModel.url
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        self.wkWebView.load(request)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
        
        // promise webview won't navigate to other link
        if url == self.viewModel.url.absoluteString {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}
