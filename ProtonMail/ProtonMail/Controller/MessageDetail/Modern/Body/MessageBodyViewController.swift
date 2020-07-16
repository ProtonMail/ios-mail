//
//  MessageBodyViewController.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageBodyViewController: HorizontallyScrollableWebViewContainer {
    private var coordinator: MessageBodyCoordinator!
    private var viewModel: MessageBodyViewModel!
    private var contentsObservation: NSKeyValueObservation!
    private var renderObservation: NSKeyValueObservation!
    
    var userDataService: UserDataService {
        return viewModel.parentViewModel.user.userService
    }

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
    var user: UserManager {
        return viewModel.parentViewModel.user
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated where navigationAction.request.url?.scheme == "mailto":
            self.coordinator?.mail(to: navigationAction.request.url!)
            decisionHandler(.cancel)
            
        case .linkActivated where navigationAction.request.url != nil:
            let url = navigationAction.request.url!
            self.validateNotPhishing(url) { [weak self] allowedToOpen in
                guard let self = self else { return }
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
    
    @available(iOS, introduced: 10.0, obsoleted: 13.0, message: "Will never be called on iOS 13 if webView(:contextMenuConfigurationForElement:completionHandler) is declared")
    override func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return self.userDataService.linkConfirmation == .openAtWill
    }
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void)
    {
        // This will show default preview and default menu
        guard self.userDataService.linkConfirmation != .openAtWill else {
            completionHandler(nil)
            return
        }
        
        // Important: as of Xcode 11.1 (11A1027) documentation claims default preview will be shown if nil is returned by the closure
        // As of iOS 13.2 - no preview is shown in this case. Not sure is it a bug or documentation misalignment.
        let config = UIContextMenuConfiguration(identifier: nil,
                                                previewProvider: { return nil },
                                                actionProvider: { UIMenu(title: "", children: $0) } )
        completionHandler(config)
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
