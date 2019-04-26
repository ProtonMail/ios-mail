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

protocol MessageBodyScrollingDelegate: class {
    func propogate(scrolling: CGPoint, boundsTouchedHandler: ()->Void)
    var scroller: UIScrollView { get }
    
    func saveOffset()
    func restoreOffset()
}

class MessageBodyViewController: UIViewController {
    private var webView: WKWebView!
    private var coordinator: MessageBodyCoordinator!
    private var viewModel: MessageBodyViewModel!
    private var contentsObservation: NSKeyValueObservation!
    
    private var height: NSLayoutConstraint!
    private var lastContentOffset: CGPoint = .zero
    private var lastZoom: CGAffineTransform = .identity
    private var initialZoom: CGAffineTransform = .identity
    private var contentSizeObservation: NSKeyValueObservation! // used to update content size after loading images
    private var renderObservation: NSKeyValueObservation!
    private var loadingObservation: NSKeyValueObservation!
    
    internal weak var enclosingScroller: MessageBodyScrollingDelegate?
    private var verticalRecognizer: UIPanGestureRecognizer!
    private var gestureInitialOffset: CGPoint = .zero
    
    private lazy var animator = UIDynamicAnimator(referenceView: self.enclosingScroller!.scroller)
    private var pushBehavior: UIPushBehavior!
    private var frictionBehaviour: UIDynamicItemBehavior!
    private var scrollDecelerationOverlay: UIView!
    private var scrollDecelerationOverlayObservation: NSKeyValueObservation!
    
    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader(addSpacerIfNeeded: false)
        } else {
            return HTMLStringSecureLoader(addSpacerIfNeeded: false)
        }
    }()
    
    deinit {
        self.contentSizeObservation = nil
        self.renderObservation = nil
        self.loadingObservation = nil
        self.contentsObservation = nil
        self.scrollDecelerationOverlayObservation = nil
        
        if let webView = self.webView {
            webView.scrollView.delegate = nil
            webView.uiDelegate = nil
            webView.navigationDelegate = nil
            self.loader.eject(from: webView.configuration)
        }
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
        }
        
        // oh, WKWebView is available in IB since iOS 11 only
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.bounces = false // otherwise 1px margin will make contents horizontally scrollable
        self.webView.scrollView.bouncesZoom = false
        self.webView.scrollView.isDirectionalLockEnabled = false
        self.webView.scrollView.showsVerticalScrollIndicator = false
        self.webView.scrollView.showsHorizontalScrollIndicator = true
        self.view.addSubview(self.webView)
        
        self.webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        self.height = self.view.heightAnchor.constraint(equalToConstant: 0.1)
        self.height.priority = .init(999.0) // for correct UITableViewCell autosizing
        self.height.isActive = true
        //
        
        self.verticalRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        self.verticalRecognizer.delegate = self
        self.verticalRecognizer.maximumNumberOfTouches = 1
        self.webView.scrollView.addGestureRecognizer(verticalRecognizer)
        
        if let contents = self.viewModel.contents {
                self.loader.load(contents: contents, in: self.webView)
        } else {
            self.webView.loadHTMLString(self.viewModel.placeholderContent, baseURL: URL(string: "about:blank"))
        }
    }
    
    @objc func pan(sender gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.animator.removeAllBehaviors()
            self.gestureInitialOffset = .zero
            self.scrollDecelerationOverlayObservation = nil
            self.scrollDecelerationOverlay?.removeFromSuperview()
            
        case .ended:
            let magic: CGFloat = 100 // this constant makes inertia feel right, something about the mass of UIKit objects
            guard let parent = self.enclosingScroller?.scroller else { return }
            self.scrollDecelerationOverlay = ViewBlowingAfterTouch(frame: .init(origin: .zero, size: parent.contentSize))
            parent.addSubview(self.scrollDecelerationOverlay)

            self.pushBehavior = UIPushBehavior(items: [self.scrollDecelerationOverlay], mode: .instantaneous)
            self.pushBehavior.pushDirection = CGVector(dx: 0, dy: -1)
            self.pushBehavior.magnitude = gesture.velocity(in: self.webView).y / magic
            self.animator.addBehavior(self.pushBehavior)
            
            self.frictionBehaviour = UIDynamicItemBehavior(items: [self.scrollDecelerationOverlay])
            self.frictionBehaviour.resistance = self.webView.scrollView.decelerationRate.rawValue
            self.frictionBehaviour.friction = 1.0
            self.frictionBehaviour.density = (magic * magic) / (self.scrollDecelerationOverlay.frame.size.height * self.scrollDecelerationOverlay.frame.size.width)
            self.animator.addBehavior(self.frictionBehaviour)
            
            self.scrollDecelerationOverlayObservation = self.scrollDecelerationOverlay.observe(\UIView.center, options: [.old, .new]) { [weak self] pixel, change in
                guard let _ = pixel.superview else { return }
                guard let new = change.newValue, let old = change.oldValue else { return }
                self?.enclosingScroller?.propogate(scrolling: .init(x: new.x - old.x, y: new.y - old.y),
                                                   boundsTouchedHandler: pixel.removeFromSuperview)
            }
            
        default:
            let translation = gesture.translation(in: self.webView)
            self.enclosingScroller?.propogate(scrolling: CGPoint(x: 0, y: self.gestureInitialOffset.y - translation.y),
                                              boundsTouchedHandler: { /* nothing */ })
            self.gestureInitialOffset = translation
        }
    }
    
    private func updateHeight(to newHeight: CGFloat) {
        self.height.constant = newHeight
        self.viewModel.contentHeight = newHeight
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.coordinator.prepare(for: segue, sender: sender)
    }
}

extension MessageBodyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // this will prevent our gesture recognizer from blocking webView's built-in gesture resognizers
        return self.webView.scrollView.gestureRecognizers?.filter{ !($0 is UITapGestureRecognizer) }.contains(otherGestureRecognizer) ?? false
    }
}

extension MessageBodyViewController: WKNavigationDelegate, WKUIDelegate, LinkOpeningValidator {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.initialZoom = webView.scrollView.subviews.first?.transform ?? .identity
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
                decisionHandler(.cancel)
            }
            
        default:
            self.contentSizeObservation = self.webView.scrollView.observe(\.contentSize, options: [.initial, .new, .old]) { [weak self] scrollView, change in
                guard change.newValue?.height != change.oldValue?.height else { return }
                guard self?.loader.renderedContents.isValid == true else { return }
                self?.updateHeight(to: scrollView.contentSize.height)
            }
            self.renderObservation = self.loader.renderedContents.observe(\.height) { [weak self] renderedContents, _ in
                guard let remoteContentMode = self?.viewModel.contents?.remoteContentMode else { return }
                self?.updateHeight(to: remoteContentMode == .allowed ? renderedContents.height : renderedContents.preheight)
            }
            self.loadingObservation = self.loadingObservation ?? self.webView.observe(\.estimatedProgress) { [weak self] webView, _ in
                guard self?.loader.renderedContents.isValid == true else { return }
                self?.updateHeight(to: webView.scrollView.contentSize.height)
            }
            decisionHandler(.allow)
        }
    }
    
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return userCachedStatus.linkOpeningMode == .allowPickAndPop
    }
}

extension MessageBodyViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.contentSizeObservation = nil
        self.renderObservation = nil
        self.loadingObservation = nil
        self.lastZoom = view?.transform ?? .identity
        self.lastContentOffset = .zero
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        var newSize = scrollView.contentSize
        newSize = newSize.applying(self.lastZoom.inverted()).applying(self.initialZoom)
        
        let united = CGPoint(x: 0, y: self.lastContentOffset.y + self.enclosingScroller!.scroller.contentOffset.y)
        self.enclosingScroller?.propogate(scrolling: self.lastContentOffset, boundsTouchedHandler: {
            // sometimes offset after zoom can exceed tableView's heigth (usually when pinch center is close to the bottom of the cell and cell after zoom should be much bigger than before)
            // here we're saying the tableView which contentOffset we'd like to have after it will increase cell and animate changes. That will cause a little glitch tho :(
            self.enclosingScroller?.scroller.contentOffset = united
            self.enclosingScroller?.saveOffset()
        })

        self.updateHeight(to: newSize.height)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isZooming {
            scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
        }
    }
}

extension MessageBodyViewController: PdfPagePrintable {
    class CustomRenderer: UIPrintPageRenderer {
        override var numberOfPages: Int {
            return self.printFormatters?.first?.pageCount ?? 0
        }
    }
    
    func printPageRenderer() -> UIPrintPageRenderer {
        let render = CustomRenderer()
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        
        render.addPrintFormatter(self.webView.viewPrintFormatter(), startingAtPageAt: 0)
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

/// This UIView removes itself from superview after first touch
fileprivate class ViewBlowingAfterTouch: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        if target == self {
            DispatchQueue.main.async {
                self.removeFromSuperview()
            }
        }
        return target
    }
}
