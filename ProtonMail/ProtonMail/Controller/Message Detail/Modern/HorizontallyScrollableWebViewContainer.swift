//
//  HorizontallyScrollableWebViewContainer.swift
//  ProtonMail - Created on 01/05/2019.
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

class HorizontallyScrollableWebViewContainer: UIViewController {
    internal var webView: WKWebView!
    
    private var height: NSLayoutConstraint!
    private var lastContentOffset: CGPoint = .zero
    private var lastZoom: CGAffineTransform = .identity
    private var initialZoom: CGAffineTransform = .identity
    private var contentSizeObservation: NSKeyValueObservation! // used to update content size after loading images
    private var loadingObservation: NSKeyValueObservation!
    
    internal weak var enclosingScroller: ScrollableContainer?
    private var enclosingScrollerObservation: NSKeyValueObservation!
    private var verticalRecognizer: UIPanGestureRecognizer!
    private var gestureInitialOffset: CGPoint = .zero
    
    private lazy var animator = UIDynamicAnimator(referenceView: self.enclosingScroller!.scroller)
    private var pushBehavior: UIPushBehavior!
    private var frictionBehaviour: UIDynamicItemBehavior!
    private var scrollDecelerationOverlay: ViewBlowingAfterTouch!
    private var scrollDecelerationOverlayObservation: NSKeyValueObservation!
    
    deinit {
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.scrollDecelerationOverlayObservation = nil
         self.enclosingScrollerObservation = nil
        
        if let webView = self.webView {
            webView.scrollView.delegate = nil
            webView.uiDelegate = nil
            webView.navigationDelegate = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.workaroundWebKitRenderingBug(swithOn: true)
    }
    
     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         self.workaroundWebKitRenderingBug(swithOn: false)
     }
    
    
     /// WebKit has a bug on iOS 10 that makes rendering incorrect when the webView is resized inside cell
     /// workaround is to relayout the webView on scrolling
     /// SO: https://stackoverflow.com/questions/39549103/wkwebview-not-rendering-correctly-in-ios-10
     ///
     /// Should be switched off by the time viewController is dismissed: iOS 9 and 10 crash if observable object (tableView) is deinit before observation (enclosingScrollerObservation) which will definitely happen cuz tableView's controller is higher in hierarchy
     private func workaroundWebKitRenderingBug(swithOn: Bool) {
         guard swithOn else {
             self.enclosingScrollerObservation = nil;
             return
         }
         if #available(iOS 11.0, *) { /* nothing */ } else if #available(iOS 10.0, *) {
             self.enclosingScrollerObservation = self.enclosingScroller?.scroller.observe(\.contentOffset) { [weak self] _, _ in
                 self?.webView?.setNeedsLayout()
             }
         } else { /* nothing */ }
     }
    
    func webViewPreferences() -> WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        preferences.javaScriptCanOpenWindowsAutomatically = false
        return preferences
    }
    
    func prepareWebView(with loader: WebContentsSecureLoader? = nil) {
        let preferences = self.webViewPreferences()
        let config = WKWebViewConfiguration()
        loader?.inject(into: config)
        config.preferences = preferences
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
        
        self.verticalRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        self.verticalRecognizer.delegate = self
        self.verticalRecognizer.maximumNumberOfTouches = 1
        self.webView.scrollView.addGestureRecognizer(verticalRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.height = self.view.heightAnchor.constraint(equalToConstant: 0.1)
        self.height.priority = .init(999.0) // for correct UITableViewCell autosizing
        self.height.isActive = true
    }
    
    @objc func pan(sender gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.animator.removeAllBehaviors()
            self.gestureInitialOffset = .zero
            self.stopInertia()
            
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
            
            self.scrollDecelerationOverlayObservation = self.scrollDecelerationOverlay.observe(\ViewBlowingAfterTouch.center, options: [.old, .new]) { [weak self] pixel, change in
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
    
    internal func stopInertia() {
        self.scrollDecelerationOverlayObservation = nil
        self.scrollDecelerationOverlay?.blow()
    }
    
    internal func updateHeight(to newHeight: CGFloat) {
        self.height.constant = newHeight
    }
    
    /// Switch off to disable observations of self.webView.scrollView.contentSize and webView.estimatedProgress
    func shouldDefaultObserveContentSizeChanges() -> Bool {
        return true
    }
}

extension HorizontallyScrollableWebViewContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // this will prevent our gesture recognizer from blocking webView's built-in gesture resognizers
        return self.webView.scrollView.gestureRecognizers?.filter{ !($0 is UITapGestureRecognizer) }.contains(otherGestureRecognizer) ?? false
    }
}

extension HorizontallyScrollableWebViewContainer: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.initialZoom = webView.scrollView.subviews.first?.transform ?? .identity
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.contentSizeObservation = self.webView.scrollView.observe(\.contentSize, options: [.initial, .new, .old]) { [weak self] scrollView, change in
            guard self?.shouldDefaultObserveContentSizeChanges() == true else { return }
            // as of iOS 13 beta 2, contentSize increases by 1pt after every updateHeight causing infinite loop. This 10pt treshold will prevent looping
            guard let new = change.newValue?.height, let old = change.oldValue?.height, new - old > 10.0 else { return }
            self?.updateHeight(to: scrollView.contentSize.height)
        }
  
        self.loadingObservation = self.loadingObservation ?? self.webView.observe(\.isLoading) { [weak self] webView, change in
            guard self?.shouldDefaultObserveContentSizeChanges() == true else { return }
            guard webView.estimatedProgress > 0.1 else { return } // skip first call because it will inherit irrelevant contentSize
            self?.updateHeight(to: webView.scrollView.contentSize.height)
        }
 
        decisionHandler(.allow)
    }
    
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false // by some reason PM do not want 3d touch here yet
    }
}

extension HorizontallyScrollableWebViewContainer: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.lastZoom = view?.transform ?? .identity
        self.lastContentOffset = .zero
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard self.shouldDefaultObserveContentSizeChanges() == true else { return } // cuz there is no zoom in Composer
        
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



/// This UIView removes itself from superview after first touch
fileprivate class ViewBlowingAfterTouch: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        if target == self {
            self.blow()
        }
        return target
    }
    
    func blow() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
}

@available(iOS 10.0, *) extension WKDataDetectorTypes {
    public static var pm_email: WKDataDetectorTypes = [.phoneNumber, .link]
}
