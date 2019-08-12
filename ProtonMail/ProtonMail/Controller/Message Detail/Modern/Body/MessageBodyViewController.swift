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

class MessageBodyViewController: HorizontallyScrollableWebViewContainer {
    private var coordinator: MessageBodyCoordinator!
    private var viewModel: MessageBodyViewModel!
    private var contentsObservation: NSKeyValueObservation!
    private var renderObservation: NSKeyValueObservation!

    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader(addSpacerIfNeeded: false)
        } else {
            return HTMLStringSecureLoader(addSpacerIfNeeded: false)
        }
    }()
    
    deinit {
        self.contentsObservation = nil
        self.renderObservation = nil
        
        if let webView = self.webView {
            self.loader.eject(from: webView.configuration)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareWebView(with: self.loader)
        
        if let contents = self.viewModel.contents, !contents.body.isEmpty {
            self.loader.load(contents: contents, in: self.webView)
        } else {
            self.webView.loadHTMLString(self.viewModel.placeholderContent, baseURL: URL(string: "about:blank"))
        }
    }

    override func updateHeight(to newHeight: CGFloat) {
        super.updateHeight(to: newHeight)
        self.viewModel.contentHeight = newHeight
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.coordinator.prepare(for: segue, sender: sender)
    }
    
    override func shouldDefaultObserveContentSizeChanges() -> Bool {
        return self.loader.renderedContents.isValid == true
    }
}

extension MessageBodyViewController : LinkOpeningValidator {
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated where navigationAction.request.url?.scheme == "mailto":
            self.coordinator?.mail(to: navigationAction.request.url!)
            decisionHandler(.cancel)
            
        case .linkActivated where navigationAction.request.url != nil:
            let url = navigationAction.request.url!
            self.validateNotPhishing(url) { allowedToOpen in
                if allowedToOpen {
                    self.coordinator?.open(url: url)
                }
            }
            decisionHandler(.cancel)
            
        default:
            self.renderObservation = self.loader.renderedContents.observe(\.height) { [weak self] renderedContents, _ in
                guard let remoteContentMode = self?.viewModel.contents?.remoteContentMode else { return }
                self?.updateHeight(to: remoteContentMode == .allowed ? renderedContents.height : renderedContents.preheight)
            }
            
            super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        }
    }
    
    @available(iOS 10.0, *)
    override func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return sharedUserDataService.linkConfirmation == .openAtWill
    }
}

extension MessageBodyViewController {
    override func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.renderObservation = nil
        super.scrollViewWillBeginZooming(scrollView, with: view)
    }
}

extension MessageBodyViewController: Printable {
    func printPageRenderer() -> UIPrintPageRenderer {
        let render = HeaderedPrintRenderer()
        let printFormatter = self.webView.viewPrintFormatter()
        render.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        return render
    }
}

extension MessageBodyViewController: ViewModelProtocol {
    func set(viewModel: MessageBodyViewModel) {
        self.viewModel = viewModel
        self.contentsObservation = self.viewModel.observe(\.contents) { [weak self] viewModel, _ in
            guard let webView = self?.webView, let contents = viewModel.contents else { return }
            self?.loader.load(contents: contents, in: webView)
        }
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
