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
    func propogate(scrolling: CGPoint)
}

class MessageBodyViewController: UIViewController {
    private var webView: WKWebView!
    private var coordinator: MessageBodyCoordinator!
    private var viewModel: MessageBodyViewModel!
    private var contentsObservation: NSKeyValueObservation!
    
    private var height: NSLayoutConstraint!
    private var lastZoom: CGAffineTransform = .identity
    private var contentSizeObservation: NSKeyValueObservation! // used to update content size after loading images
    
    internal weak var enclosingScroller: MessageBodyScrollingDelegate?
    private var verticalRecognizer: UIPanGestureRecognizer!
    private var gestureInitialOffset: CGPoint = .zero
    
    private lazy var animator = UIDynamicAnimator(referenceView: self.webView.scrollView)
    private var pushBehavior: UIPushBehavior!
    private var frictionBehaviour: UIDynamicItemBehavior!
    private var scrollDecelerationOverlay: UIView!
    private var scrollDecelerationOverlayObservation: NSKeyValueObservation!
    
    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader(addSpacerIfNeeded: false)
        } else {
            return HTMLStringSecureLoader()
        }
    }()
    
    deinit {
        if let webView = self.webView {
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
        self.webView.scrollView.delegate = self
        self.webView.scrollView.bounces = true
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
            self.scrollDecelerationOverlay = ViewBlowingAfterTouch(frame: .init(origin: .zero, size: self.webView.scrollView.contentSize))
            self.webView.scrollView.addSubview(self.scrollDecelerationOverlay)

            self.pushBehavior = UIPushBehavior(items: [self.scrollDecelerationOverlay], mode: .instantaneous)
            self.pushBehavior.pushDirection = CGVector(dx: 0, dy: -1)
            self.pushBehavior.magnitude = gesture.velocity(in: self.webView).y / magic
            self.animator.addBehavior(self.pushBehavior)
            
            self.frictionBehaviour = UIDynamicItemBehavior(items: [self.scrollDecelerationOverlay])
            self.frictionBehaviour.resistance = self.webView.scrollView.decelerationRate.rawValue
            self.frictionBehaviour.density = (magic * magic) / (self.scrollDecelerationOverlay.frame.size.height * self.scrollDecelerationOverlay.frame.size.width)
            self.animator.addBehavior(self.frictionBehaviour)
            
            self.scrollDecelerationOverlayObservation = self.scrollDecelerationOverlay.observe(\UIView.center, options: [.old, .new]) { [weak self] pixel, change in
                guard let _ = pixel.superview else { return }
                guard let new = change.newValue, let old = change.oldValue else { return }
                self?.enclosingScroller?.propogate(scrolling: .init(x: new.x - old.x, y: new.y - old.y))
            }
            
        default:
            let translation = gesture.translation(in: self.webView)
            self.enclosingScroller?.propogate(scrolling: CGPoint(x: 0, y: self.gestureInitialOffset.y - translation.y))
            self.gestureInitialOffset = translation
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loader.load(contents: self.viewModel.contents, in: webView)
    }
    
    private func updateHeight(to newHeight: CGFloat) {
        self.height.constant = newHeight
        self.viewModel.contentSize = self.webView.scrollView.contentSize
    }
    
    private func reload() {
        // not the most efficient way, but if we do not want to run JS in these webviews - we have to shrink the cell to it's minimum, let webView define it's contents size and then resize cell up to the correct height
        // otherwise webView will try to match it's current height and will add bottom spacer to the contents, which will screw up contentSize and it will grow with every transition bigger and bigger
        self.height.constant = 111.0
        self.webView.reload()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.reload()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.coordinator.prepare(for: segue, sender: sender)
    }
}

extension MessageBodyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // this will prevent our gesture recognizer from blocking webView's built-in gesture resognizers
        return self.webView.scrollView.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
    }
}

extension MessageBodyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.updateHeight(to: webView.scrollView.contentSize.height)
        self.contentSizeObservation = self.webView.scrollView.observe(\.contentSize, options: [.old, .new]) { [weak self] scrollView, change in
            guard let old = change.oldValue, let new = change.newValue,
                old.height != new.height else { return }
            self?.updateHeight(to: new.height)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated where navigationAction.request.url?.scheme == "mailto":
            self.coordinator?.mail(to: navigationAction.request.url!)
            decisionHandler(.cancel)
            
        case .linkActivated where navigationAction.request.url != nil:
            self.coordinator?.open(url: navigationAction.request.url!)
            decisionHandler(.cancel)
            
        default:
            decisionHandler(.allow)
            self.contentSizeObservation = nil
        }
    }
    
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false // by some reason PM do not want 3d touch here yet
    }
}

extension MessageBodyViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.contentSizeObservation = nil
        self.lastZoom = view?.transform ?? .identity
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        var newSize = scrollView.contentSize
        newSize = newSize.applying(self.lastZoom.inverted())
        self.updateHeight(to: newSize.height)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
    }
}

extension MessageBodyViewController: ViewModelProtocol {
    func set(viewModel: MessageBodyViewModel) {
        self.viewModel = viewModel
        self.contentsObservation = self.viewModel.observe(\.contents) { [weak self] viewModel, _ in
            guard let webView = self?.webView else { return }
            self?.loader.load(contents: viewModel.contents, in: webView)
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
            self.removeFromSuperview()
        }
        return target
    }
}
