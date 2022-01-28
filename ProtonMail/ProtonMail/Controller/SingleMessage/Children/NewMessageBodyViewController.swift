//
//  NewMessageBodyViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_UIFoundations
import TrustKit
import UIKit
import WebKit

protocol NewMessageBodyViewControllerDelegate: AnyObject {
    func openUrl(_ url: URL)
    func openMailUrl(_ mailUrl: URL)
    func openFullCryptoPage()
    func updateContentBanner(shouldShowRemoteContentBanner: Bool,
                             shouldShowEmbeddedContentBanner: Bool)
    func showDecryptionErrorBanner()
    func hideDecryptionErrorBanner()
}

class NewMessageBodyViewController: UIViewController {

    private let viewModel: NewMessageBodyViewModel
    private weak var scrollViewContainer: ScrollableContainer!
    private lazy var customView = NewMessageBodyView()

    private lazy var loader: WebContentsSecureLoader = {
        HTTPRequestSecureLoader(addSpacerIfNeeded: false)
    }()
    weak var delegate: NewMessageBodyViewControllerDelegate?
    private(set) var webView: WKWebView?

    /// used to update content size after loading images
    private var contentSizeObservation: NSKeyValueObservation!
    private var loadingObservation: NSKeyValueObservation!

    private var heightConstraint: NSLayoutConstraint?
    private var originalHeight: CGFloat = 0.0

    // Handle zoom in gesture in webview
    private lazy var animator = UIDynamicAnimator(referenceView: self.scrollViewContainer.scroller)
    private var pushBehavior: UIPushBehavior!
    private var frictionBehaviour: UIDynamicItemBehavior!
    private var scrollDecelerationOverlay: ViewBlowingAfterTouch!
    private var scrollDecelerationOverlayObservation: NSKeyValueObservation!
    private var enclosingScrollerObservation: NSKeyValueObservation!
    private var verticalRecognizer: UIPanGestureRecognizer?
    private var gestureInitialOffset: CGPoint = .zero

    private var lastContentOffset: CGPoint = .zero
    private var lastZoom: CGAffineTransform = .identity
    private var initialZoom: CGAffineTransform = .identity
    private var defaultScale: CGFloat?
    private let viewMode: ViewMode

    init(viewModel: NewMessageBodyViewModel, parentScrollView: ScrollableContainer, viewMode: ViewMode) {
        self.viewModel = viewModel
        self.scrollViewContainer = parentScrollView
        self.viewMode = viewMode
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }

    deinit {
        if let webView = webView {
            self.loader.eject(from: webView.configuration)
        }
    }

    override func loadView() {
        view = customView
    }

    required init?(coder: NSCoder) {
        nil
    }

    private(set) var placeholder: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.prepareWebView(with: self.loader)

        guard let webView = self.webView else {
            return
        }

        if let contents = self.viewModel.contents, !contents.body.isEmpty {
            self.loader.load(contents: contents, in: webView)

            self.loader.observeHeight { [weak self] height in
                self?.updateViewHeight(to: height)
                self?.viewModel.recalculateCellHeight?(true)
            }
        } else if viewModel.internetStatusProvider.currentStatus == .NotReachable &&
                    !viewModel.message.isDetailDownloaded {
            prepareReloadView()
        } else {
            placeholder = true
            webView.loadHTMLString(self.viewModel.placeholderContent, baseURL: URL(string: "about:blank"))
        }

        setupContentSizeObservation()
    }

    func prepareReloadView() {
        self.customView.alertTextLabel.text = LocalString._message_body_view_not_connected_text
        var textAttribute = FontManager.Default
        textAttribute[.foregroundColor] = ColorProvider.TextInverted
        self.customView.addReloadView()

        self.heightConstraint?.isActive = false
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 300)
        heightConstraint.priority = .init(999.0)
        [heightConstraint].activate()
        self.heightConstraint = heightConstraint
    }

    func prepareWebView(with loader: WebContentsSecureLoader? = nil) {
        view.removeConstraints(view.constraints.filter({ $0.firstAnchor == view.heightAnchor }))

        self.heightConstraint?.isActive = false
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 50)
        heightConstraint.priority = .init(999.0)
        [heightConstraint].activate()
        self.heightConstraint = heightConstraint

        let preferences = viewModel.webViewPreferences
        let config = viewModel.webViewConfig
        config.preferences = preferences
        loader?.inject(into: config)

        if let existingWebView = self.webView {
            existingWebView.stopLoading()
        } else {
            self.webView = PMWebView(frame: .zero, configuration: config)
            guard let webView = self.webView else {
                return
            }

			// This fixes the white screen issue in dark mode.
	        webView.isOpaque = false
            webView.backgroundColor = ColorProvider.BackgroundNorm
			webView.translatesAutoresizingMaskIntoConstraints = false
            webView.navigationDelegate = self
            webView.uiDelegate = self
            if viewMode == .singleMessage {
                webView.scrollView.delegate = self
                // Work around for webview tap too sensitive. Disable the recognizer when the view is just loaded.
                webView.scrollView.isScrollEnabled = false
            }
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            webView.scrollView.bounces = false // otherwise 1px margin will make contents horizontally scrollable
            webView.scrollView.bouncesZoom = false
            webView.scrollView.isDirectionalLockEnabled = false
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.showsHorizontalScrollIndicator = true

            self.customView.embed(webView)
        }

        if viewMode == .singleMessage {
            self.prepareGestureRecognizer()
        }
    }

    private func updateViewHeight(to newHeight: CGFloat) {
        heightConstraint?.constant = newHeight
    }

    private func prepareGestureRecognizer() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        self.verticalRecognizer = gesture
        if #available(iOS 13.4, *) {
            self.verticalRecognizer?.allowedScrollTypesMask = .all
        }
        self.verticalRecognizer?.delegate = self
        self.verticalRecognizer?.maximumNumberOfTouches = 1
        self.webView?.scrollView.addGestureRecognizer(gesture)
        self.verticalRecognizer?.isEnabled = false
    }

    private func stopInertia() {
        self.scrollDecelerationOverlayObservation = nil
        self.scrollDecelerationOverlay?.blow()
    }

    var updatesTimer: Timer? {
        didSet { oldValue?.invalidate() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard placeholder == false else { return }
        if webView.isLoading {
            updatesTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                self?.updateViewHeight(to: webView.scrollView.contentSize.height)
                self?.viewModel.recalculateCellHeight?(true)
            })
        } else {
            updatesTimer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.updateViewHeight(to: webView.scrollView.contentSize.height)
                self?.viewModel.recalculateCellHeight?(true)
            }
        }
    }

    @objc
    private func pan(sender gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.animator.removeAllBehaviors()
            self.gestureInitialOffset = .zero
            self.stopInertia()

        case .ended:
            /// this constant makes inertia feel right, something about the mass of UIKit objects
            let magic: CGFloat = 100
            let parent = self.scrollViewContainer.scroller
            self.scrollDecelerationOverlay =
                ViewBlowingAfterTouch(frame: .init(origin: .zero, size: parent.contentSize))
            parent.addSubview(self.scrollDecelerationOverlay)

            self.pushBehavior = UIPushBehavior(items: [self.scrollDecelerationOverlay], mode: .instantaneous)
            self.pushBehavior.pushDirection = CGVector(dx: 0, dy: -1)
            self.pushBehavior.magnitude = gesture.velocity(in: self.webView).y / magic
            self.animator.addBehavior(self.pushBehavior)

            self.frictionBehaviour = UIDynamicItemBehavior(items: [self.scrollDecelerationOverlay])
            self.frictionBehaviour.resistance = self.webView?.scrollView.decelerationRate.rawValue ?? 0.0
            self.frictionBehaviour.friction = 1.0

            let viewSize = self.scrollDecelerationOverlay.frame.size
            let viewArea = viewSize.height * viewSize.width
            self.frictionBehaviour.density = (magic * magic) / viewArea
            self.animator.addBehavior(self.frictionBehaviour)

            self.scrollDecelerationOverlayObservation = self.scrollDecelerationOverlay
                .observe(\ViewBlowingAfterTouch.center,
                         options: [.old, .new]) { [weak self] pixel, change in
                    guard pixel.superview != nil else { return }
                    guard let new = change.newValue, let old = change.oldValue else { return }
                    self?.scrollViewContainer.propagate(scrolling: .init(x: new.x - old.x, y: new.y - old.y),
                                                        boundsTouchedHandler: pixel.removeFromSuperview)
                }

        default:
            let translation = gesture.translation(in: self.webView)
            self.scrollViewContainer.propagate(scrolling: CGPoint(x: 0, y: self.gestureInitialOffset.y - translation.y),
                                               boundsTouchedHandler: { /* nothing */ })
            self.gestureInitialOffset = translation
        }
    }

    private func setupContentSizeObservation() {
        self.contentSizeObservation =
            self.webView?.scrollView.observe(\.contentSize,
                                             options: [.initial, .new, .old]) { [weak self] scrollView, change in
                guard let webView = self?.webView else { return }
                // As of iOS 13 beta 2, contentSize increases by 1pt after every updateHeight causing infinite loop.
                // This 10pt treshold will prevent looping
                guard let new = change.newValue?.height,
                      let old = change.oldValue?.height,
                      new - old > 10.0 else { return }

                // Update the original height here for the web page that has image to be downloaded.
                self?.originalHeight = webView.scrollView.contentSize.height
            }

        guard self.loadingObservation == nil else {
            return
        }

        self.loadingObservation = self.webView?.observe(\.isLoading,
                                                        options: [.initial, .new, .old]) { [weak self] webView, _ in
            // skip first call because it will inherit irrelevant contentSize

            guard webView.estimatedProgress > 0.1 else { return }

            // Work around for webview tap too sensitive. Save the default scale value
            self?.defaultScale = round(webView.scrollView.zoomScale * 1_000) / 1_000.0
        }
    }

}

extension NewMessageBodyViewController: NewMessageBodyViewModelDelegate {
    func updateBannerStatus() {
        delegate?.updateContentBanner(shouldShowRemoteContentBanner: viewModel.shouldShowRemoteBanner,
                                      shouldShowEmbeddedContentBanner: viewModel.shouldShowEmbeddedBanner)
    }

    func showReloadError() {
        self.prepareReloadView()
    }

    func reloadWebView(forceRecreate: Bool) {
        // Prevent unnecessary webView reload
        guard isViewLoaded else {
            return
        }

        self.customView.removeReloadView()
        guard let contents = viewModel.contents else { return }

        if forceRecreate {
            self.prepareWebView(with: self.loader)
            if let webView = self.webView {
                placeholder = false
                self.loader.load(contents: contents, in: webView)
            }
        } else {
            if let webView = self.webView {
                if !customView.subviews.contains(webView) {
                    customView.embed(webView)
                }
                placeholder = false
                self.loader.load(contents: contents, in: webView)
            } else {
                self.prepareWebView(with: self.loader)
                if let webView = self.webView {
                    placeholder = false
                    self.loader.load(contents: contents, in: webView)
                }
            }
        }
    }

    func showDecryptionErrorBanner() {
        self.delegate?.showDecryptionErrorBanner()
    }

    func hideDecryptionErrorBanner() {
        self.delegate?.hideDecryptionErrorBanner()
    }
}

extension NewMessageBodyViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if PMAPIService.noTrustKit {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        } else if let validator = PMAPIService.trustKit?.pinningValidator {
            if !validator.handle(challenge, completionHandler: completionHandler) {
                completionHandler(.performDefaultHandling, challenge.proposedCredential)
            }
        } else {
            assert(false, "TrustKit was not correctly initialized")
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }
}

extension NewMessageBodyViewController: LinkOpeningValidator {
    var linkConfirmation: LinkOpeningMode {
        return viewModel.linkConfirmation
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated where navigationAction.request.url?.scheme == "mailto":
            if let url = navigationAction.request.url {
                self.delegate?.openMailUrl(url)
            }
            decisionHandler(.cancel)

        case .linkActivated where navigationAction.request.url != nil:
            defer { decisionHandler(.cancel) }
            guard let url = navigationAction.request.url else { return }
            if url.absoluteString == String.fullDecryptionFailedViewLink {
                self.delegate?.openFullCryptoPage()
                return
            }

            self.validateNotPhishing(url) { [weak self] allowedToOpen in
                guard let self = self else { return }
                if allowedToOpen {
                    self.delegate?.openUrl(url)
                }
            }
        default:
            decisionHandler(.allow)
        }
    }

    // Won't be called on iOS 13 if webView(:contextMenuConfigurationForElement:completionHandler) is declared
    @available(iOS, introduced: 10.0, obsoleted: 13.0, message: "")
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return linkConfirmation == .openAtWill
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        // This will show default preview and default menu
        guard linkConfirmation != .openAtWill else {
            completionHandler(nil)
            return
        }

        /* Important: as of Xcode 11.1 (11A1027) documentation claims default preview will be shown
         if nil is returned by the closure.
         As of iOS 13.2 - no preview is shown in this case. Not sure is it a bug or documentation misalignment.*/
        let config = UIContextMenuConfiguration(identifier: nil,
                                                previewProvider: { nil },
                                                actionProvider: { UIMenu(title: "", children: $0) })
        completionHandler(config)
    }
}

extension NewMessageBodyViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.webView?.scrollView.isScrollEnabled = true
        self.verticalRecognizer?.isEnabled = true
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.lastZoom = view?.transform ?? .identity
        self.lastContentOffset = .zero
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let united = CGPoint(x: 0, y: self.lastContentOffset.y + self.scrollViewContainer.scroller.contentOffset.y)
        self.scrollViewContainer.propagate(scrolling: self.lastContentOffset, boundsTouchedHandler: {
            /* Sometimes offset after zoom can exceed tableView's heigth
                (usually when pinch center is close to the bottom of the cell
                and cell after zoom should be much bigger than before).
             Here we're saying the tableView which contentOffset we'd like to have
                after it will increase cell and animate changes.
                That will cause a little glitch tho :( */
            self.scrollViewContainer.scroller.contentOffset = united
            self.scrollViewContainer.saveOffset()
        })

        self.updateViewHeight(to: scrollView.contentSize.height)

        // Work around for webview tap too sensitive
        if let defaultScale = self.defaultScale {
            if round(scrollView.zoomScale * 1_000) / 1_000.0 == defaultScale {
                self.webView?.scrollView.isScrollEnabled = false
                self.verticalRecognizer?.isEnabled = false
                if self.originalHeight >= 0 {
                    self.updateViewHeight(to: self.originalHeight)
                }
                return
            }
        }
        self.webView?.scrollView.isScrollEnabled = true
        self.verticalRecognizer?.isEnabled = true
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let defaultScale = self.defaultScale {
            if round(scrollView.zoomScale * 1_000) / 1_000.0 == defaultScale {
                scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
            }
        }
    }
}

extension NewMessageBodyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // this will prevent our gesture recognizer from blocking webView's built-in gesture resognizers
        return self.webView?.scrollView.gestureRecognizers?
            .filter { !($0 is UITapGestureRecognizer) }.contains(otherGestureRecognizer) ?? false
    }
}

/// This UIView removes itself from superview after first touch
private class ViewBlowingAfterTouch: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        if target == self {
            self.blow()
            return nil
        }
        return target
    }

    func blow() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
}
