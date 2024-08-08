//
//  NewMessageBodyViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreDataModel
import ProtonCoreServices
import ProtonCoreUIFoundations
import SkeletonView
import TrustKit
import UIKit
import WebKit

protocol NewMessageBodyViewControllerDelegate: AnyObject {
    func openUrl(_ url: URL)
    func openMailUrl(_ mailUrl: URL)
    func openFullCryptoPage()
}

class NewMessageBodyViewController: UIViewController {

    private let viewModel: NewMessageBodyViewModel
    private weak var scrollViewContainer: ScrollableContainer!
    private lazy var customView = NewMessageBodyView()

    private lazy var loader: HTTPRequestSecureLoader = {
        HTTPRequestSecureLoader(schemeHandler: .init(
            userKeys: viewModel.userKeys,
            imageProxy: viewModel.imageProxy
        ))
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
    private var verticalRecognizer: UIPanGestureRecognizer?
    private var gestureInitialOffset: CGPoint = .zero

    private var lastContentOffset: CGPoint = .zero
    private var defaultScale: CGFloat?
    private let viewMode: ViewMode
    private var expectedSwipeAction = PagesSwipeAction.noAction
    private var webViewDefaultScollable = false
    /// Start to load webContent or paused due to wrong webView size
    private var hasLoadedContent = false

    var webViewIsLoaded: (() -> Void)?

    var isLoading: Bool {
        return webView?.isLoading ?? false
    }

    var isWebViewInDefaultScale: Bool {
        guard let defaultScale = self.defaultScale, let scrollView = webView?.scrollView else {
            return false
        }
        return round(scrollView.zoomScale * 1_000) / 1_000.0 == defaultScale
    }

    private var fontSizeHasBeenAdjusted = false

    init(viewModel: NewMessageBodyViewModel, parentScrollView: ScrollableContainer, viewMode: ViewMode) {
        self.viewModel = viewModel
        self.scrollViewContainer = parentScrollView
        self.viewMode = viewMode
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        loader.delegate = self
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
            hasLoadedContent = self.loader.load(contents: contents, in: webView)
        } else if viewModel.internetStatusProvider.status == .notConnected &&
                    viewModel.contents == nil {
            prepareReloadView()
        } else {
            placeholder = true
            webView.loadHTMLString(self.viewModel.placeholderContent, baseURL: URL(string: "about:blank"))
        }
        self.loader.observeHeight { [weak self] height in
            self?.updateViewHeight(to: height)
            self?.viewModel.recalculateCellHeight?(true)
        }
        loader.observeContentShouldBeScrollableByDefault { [weak self] shouldBeScrollableByDefault in
            self?.webViewDefaultScollable = shouldBeScrollableByDefault
            if self?.webView?.scrollView.isZooming == false {
                webView.scrollView.isScrollEnabled = shouldBeScrollableByDefault
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(doEnterForeground),
            name: UIWindowScene.willEnterForegroundNotification,
            object: nil
        )

        setupContentSizeObservation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasLoadedContent {
            // Load content, since the previous loading is paused due to wrong webView size
            reloadWebView(forceRecreate: false)
        }
    }

    func prepareReloadView() {
        self.customView.alertTextLabel.text = LocalString._message_body_view_not_connected_text
        var textAttribute = FontManager.Default
        textAttribute[.foregroundColor] = ColorProvider.TextInverted as UIColor
        self.customView.addReloadView()

        self.heightConstraint?.isActive = false
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 300)
        heightConstraint.priority = .init(999.0)
        [heightConstraint].activate()
        self.heightConstraint = heightConstraint
    }

    private func prepareWebView(with loader: HTTPRequestSecureLoader? = nil) {
        view.removeConstraints(view.constraints.filter({ $0.firstAnchor == view.heightAnchor }))

        self.heightConstraint?.isActive = false
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 500)
        heightConstraint.priority = .init(999.0)
        [heightConstraint].activate()
        self.heightConstraint = heightConstraint

        let config = viewModel.webViewConfig
        loader?.inject(into: config)

        if let existingWebView = self.webView {
            existingWebView.stopLoading()
        } else {
            self.webView = PMWebView(frame: .zero, configuration: config)
            #if DEBUG
            if #available(iOS 16.4, *) {
                self.webView?.isInspectable = true
            }
            #endif
            guard let webView = self.webView else {
                return
            }

			// This fixes the white screen issue in dark mode.
	        webView.isOpaque = false
            webView.backgroundColor = ColorProvider.BackgroundNorm
			webView.translatesAutoresizingMaskIntoConstraints = false
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.scrollView.delegate = self
            // Work around for webview tap too sensitive. Disable the recognizer when the view is just loaded.
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            webView.scrollView.bounces = false // otherwise 1px margin will make contents horizontally scrollable
            webView.scrollView.bouncesZoom = false
            webView.scrollView.isDirectionalLockEnabled = false
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.showsHorizontalScrollIndicator = true

            self.customView.embed(webView)
            showSkeletonView()
        }

        if viewMode == .singleMessage {
            self.prepareGestureRecognizer()
        }
    }

    private func updateViewHeight(to newHeight: CGFloat) {
        // Limit the maximum height of the view height to the original height * 3.
        // This can prevent the height constraint becoming too large to be invalid and break the UI layout.
        let height = min(originalHeight * 3, newHeight)
        heightConstraint?.constant = height
        viewModel.recalculateCellHeight?(true)
    }

    private func prepareGestureRecognizer() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        self.verticalRecognizer = gesture
            self.verticalRecognizer?.allowedScrollTypesMask = .all
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
            updateDynamicFontSize()
            updatesTimer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.updateViewHeight(to: webView.scrollView.contentSize.height)
                self?.viewModel.recalculateCellHeight?(true)
                // Scroll the highlighted keyword in ES to the center of the webview.
                self?.scrollTo(anchor: "es-autoscroll", in: webView)
                self?.webViewIsLoaded?()
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
                // As of iOS 13 beta 2, contentSize increases by 1pt after every updateHeight causing infinite loop.
                // This 10pt treshold will prevent looping
                guard let new = change.newValue?.height,
                      let old = change.oldValue?.height,
                      new - old > 10.0 else { return }

                // Update the original height here for the web page that has image to be downloaded.
                self?.originalHeight = scrollView.contentSize.height
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

    @objc
    private func doEnterForeground() {
        let script = """
        const bodyHeight = document.body.scrollHeight;
        const radio = document
        .querySelector('meta[name="viewport"]')
        .attributes['content']
        .value
        .match(/initial-scale=(.*?),/)[1];
        
        bodyHeight * radio
        """
        webView?.evaluateJavaScript(script, completionHandler: { [weak self] result, error in
            // JavaScript seems like won't execute in the background
            // If message is opened in the background, webView height could not be updated to the correct value
            // Double check height after back to foreground 
            guard
                error == nil,
                let height = result as? Double,
                let constraint = self?.heightConstraint?.constant,
                height > constraint
            else { return }
            self?.updateViewHeight(to: height)
        })
    }

    func preferredContentSizeChanged() {
        updateDynamicFontSize()
    }

    func updateDynamicFontSize() {
        let isUsingDefaultSizeCategory = view.traitCollection.preferredContentSizeCategory == .large

        if isUsingDefaultSizeCategory {
            if fontSizeHasBeenAdjusted {
                SystemLogger.log(
                    message: "Reverting to default content size category",
                    category: .dynamicFontSize
                )
                resetMessageContentFontSize()
            } else {
                SystemLogger.log(
                    message: "Using default content size category, no adjustment needed",
                    category: .dynamicFontSize
                )
            }
        } else {
            SystemLogger.log(message: "Adjusting content size category", category: .dynamicFontSize)
            scaleMessageContentFontSize()
        }
    }

    private func scaleMessageContentFontSize() {
        fontSizeHasBeenAdjusted = true
        runDynamicFontSizeCode(functionName: "scaleContentSize")
    }

    private func resetMessageContentFontSize() {
        fontSizeHasBeenAdjusted = false
        runDynamicFontSizeCode(functionName: "resetContentSize")
    }

    private func runDynamicFontSizeCode(functionName: String) {
        webView?.evaluateJavaScript("\(functionName)();") { _, error in
            if let error {
                SystemLogger.log(error: error, category: .dynamicFontSize)
            } else {
                SystemLogger.log(message: "Content size updated", category: .dynamicFontSize)
            }
        }
    }
}

extension NewMessageBodyViewController: NewMessageBodyViewModelDelegate {
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
                hasLoadedContent = self.loader.load(contents: contents, in: webView)
            }
        } else {
            if let webView = self.webView {
                if !customView.subviews.contains(webView) {
                    customView.embed(webView)
                }
                placeholder = false
                hasLoadedContent = self.loader.load(contents: contents, in: webView)
            } else {
                self.prepareWebView(with: self.loader)
                if let webView = self.webView {
                    placeholder = false
                    hasLoadedContent = self.loader.load(contents: contents, in: webView)
                }
            }
        }
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

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.removeFromSuperview()
        webView.stopLoading()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        self.webView = nil
        reloadWebView(forceRecreate: true)
    }
}

extension NewMessageBodyViewController {
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
            guard var url = navigationAction.request.url else { return }

            if url.absoluteString == String.fullDecryptionFailedViewLink {
                self.delegate?.openFullCryptoPage()
                return
            }

            if let currentURL = webView.url,
               url.absoluteString.hasPrefix(currentURL.absoluteString),
               let fragment = url.fragment {
                scrollTo(anchor: fragment, in: webView)
                return
            }

            url = url.removeProtonSchemeIfNeeded()

            let isFromPhishingMail = viewModel.spam == .autoPhishing
            guard viewModel.shouldOpenPhishingAlert(url, isFromPhishingMsg: isFromPhishingMail) else {
                self.delegate?.openUrl(url)
                return
            }
            let alertContent = viewModel.generatePhishingAlertContent(url, isFromPhishingMsg: isFromPhishingMail)
            let alert: UIAlertController
            if isFromPhishingMail {
                alert = makeSpamLinkConfirmationAlert(title: alertContent.0,
                                                      message: alertContent.1) { allowedToOpen in
                    if allowedToOpen {
                        self.delegate?.openUrl(url)
                    }
                }
            } else {
                alert = makeLinkConfirmationAlert(title: alertContent.0,
                                                  message: alertContent.1) { allowedToOpen in
                    if allowedToOpen {
                        self.delegate?.openUrl(url)
                    }
                }
            }

            self.present(alert, animated: true, completion: nil)
        default:
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        // This will show default preview and default menu
        guard viewModel.linkConfirmation != .openAtWill else {
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

    private func scrollTo(anchor: String, in webView: WKWebView) {
        let script = """
        var anchor = document.getElementById('\(anchor)')
        if (anchor != undefined) {
          window.pageYOffset + anchor.getBoundingClientRect().top
        }
        """

        webView.evaluateJavaScript(script) { [weak self] output, error in
            if let error = error {
                assertionFailure("\(error)")
                return
            }

            guard let self = self, let offset = output as? CGFloat else { return }

            let target = CGPoint(x: 0, y: offset)
            let contentOffset = self.view.convert(target, to: self.scrollViewContainer.scroller)
            self.scrollViewContainer.scroller.setContentOffset(contentOffset, animated: true)
        }
    }

    private func makeLinkConfirmationAlert(title: String,
                                           message: String,
                                           urlHandler: @escaping (Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let proceed = UIAlertAction(title: LocalString._genernal_continue, style: .destructive) { _ in
            urlHandler(true)
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { _ in
            urlHandler(false)
        }
        [proceed, cancel].forEach(alert.addAction)
        return alert
    }

    private func makeSpamLinkConfirmationAlert(title: String,
                                               message: String,
                                               urlHandler: @escaping (Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: LocalString._spam_open_go_back, style: .cancel) { _ in
            urlHandler(false)
        }
        let proceed = UIAlertAction(title: LocalString._spam_open_continue, style: .destructive) { _ in
            urlHandler(true)
        }
        [cancel, proceed].forEach(alert.addAction)
        return alert
    }
}

extension NewMessageBodyViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.webView?.scrollView.isScrollEnabled = true
        self.verticalRecognizer?.isEnabled = true
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.lastContentOffset = .zero
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let united = CGPoint(x: 0, y: self.lastContentOffset.y + self.scrollViewContainer.scroller.contentOffset.y)

        if verticalRecognizer != nil {
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
        }

        self.updateViewHeight(to: scrollView.contentSize.height)

        // Work around for webview tap too sensitive
        if isWebViewInDefaultScale {
            webView?.scrollView.isScrollEnabled = webViewDefaultScollable
            verticalRecognizer?.isEnabled = false
            if originalHeight >= 0 {
                updateViewHeight(to: originalHeight)
            }
            return
        }
        self.webView?.scrollView.isScrollEnabled = true
        self.verticalRecognizer?.isEnabled = true
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let defaultScale = self.defaultScale,
           round(scrollView.zoomScale * 1_000) / 1_000.0 == defaultScale,
           // Some messages could have issue while rendering inside the WebView. The content size of it will keep increasing by 1px.
           // And this behavior causes the height of the contentSize is bigger than the height of the frame even the zoomScale is zero.
           // Here we double check if this message has this kind of issue.
           scrollView.contentSize.height < scrollView.frame.height {
            scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // ContentOffset needs sometime to update to final status
        delay(0.3) {
            let translation = scrollView.panGestureRecognizer.translation(in: self.webView)
            let current = scrollView.contentOffset
            let width = scrollView.frame.width
            let contentWidth = scrollView.contentSize.width

            let absX = abs(translation.x)
            let absY = abs(translation.y)
            // tan(25) = 0.466_307_658_15, why 25? by feeling
            // a horizontal swipe drag angle is less than 25 degree
            guard absX > absY && absY / absX <= 0.466_307_658_15 else {
                self.expectedSwipeAction = .noAction
                return
            }
            let action: PagesSwipeAction
            if current.x <= 0 && translation.x > 0 {
                action = .backward
            } else if current.x + width >= contentWidth && translation.x < 0 {
                action = .forward
            } else {
                action = .noAction
            }
            guard self.expectedSwipeAction == action && action != .noAction else {
                self.expectedSwipeAction = action
                return
            }
            self.expectedSwipeAction = .noAction
            NotificationCenter.default.post(
                name: .pagesSwipeExpectation,
                object: nil,
                userInfo: ["expectation": action]
            )
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

// MARK: - HTTPRequestSecureLoaderDelegate
extension NewMessageBodyViewController: HTTPRequestSecureLoaderDelegate {
    func showSkeletonView() {
        guard let webView = self.webView else { return }
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.isSkeletonable = true
        label.linesCornerRadius = 5
        label.lastLineFillPercent = 30
        label.skeletonTextNumberOfLines = 5
        webView.addSubview(label)
        [
            label.topAnchor.constraint(equalTo: webView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: webView.bottomAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: webView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -16)
        ].activate()
        label.showAnimatedGradientSkeleton()
    }

    func hideSkeletonView() {
        guard let webView = self.webView else { return }
        webView.subviews.compactMap { $0 as? UILabel }.forEach { view in
            view.stopSkeletonAnimation()
            view.removeFromSuperview()
        }
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
