//
//  EditorViewController.swift
//  Proton Mail - Created on 25/03/2019.
//
//
//  Copyright (c) 2019 Proton AG
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

import UIKit
import PromiseKit
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import WebKit

/// The class hierarchy is following: ContainableComposeViewController > ComposeViewController > HorizontallyScrollableWebViewContainer > UIViewController
///
/// HtmlEditorBehavior only adds some functionality to HorizontallyScrollableWebViewContainer's webView, is not a UIView or webView's delegate any more. ComposeViewController is tightly coupled with ComposeHeaderViewController and needs separate refactor, while ContainableComposeViewController and HorizontallyScrollableWebViewContainer contain absolute minimum of logic they need: logic allowing to embed composer into tableView cell and logic allowing 2D scroll in fullsize webView.
///
class ContainableComposeViewController: ComposeContentViewController, BannerRequester {
    typealias Dependencies = ComposeContentViewController.Dependencies
    & HasInternetConnectionStatusProviderProtocol
    & HasKeyMakerProtocol
    & HasQueueManager

    private let dependencies: Dependencies
    private var latestErrorBanner: BannerView?
    private var heightObservation: NSKeyValueObservation!
    private var queueObservation: NSKeyValueObservation!

    init(viewModel: ComposeViewModel, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(viewModel: viewModel, dependencies: dependencies)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        self.webView.scrollView.clipsToBounds = false
        
        self.heightObservation = self.htmlEditor.observe(\.contentHeight, options: [.new, .old]) { [weak self] htmlEditor, change in
            guard let self = self, change.oldValue != change.newValue else { return }

            let totalHeight = htmlEditor.contentHeight
            self.updateHeight(to: totalHeight)
            self.viewModel.contentHeight = totalHeight
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.willShowMenuNotification), name: UIMenuController.willShowMenuNotification, object: nil)

        // notifications
        #if APP_EXTENSION
        NotificationCenter.default.addObserver(self, selector: #selector(self.errorOccurredNotification(notification:)), name: NSError.errorOccuredNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.noErrorNotification), name: NSError.noErrorNotification, object: nil)
        #endif
        generateAccessibilityIdentifiers()
    }

    @objc func removeStyleFromSelection() {
        self.htmlEditor.removeStyleFromSelection()
    }

    @objc private func willShowMenuNotification() {
        let saveMenuItem = UIMenuItem(title: LocalString._clear_style, action: #selector(self.removeStyleFromSelection))
        UIMenuController.shared.menuItems = [saveMenuItem]
    }

    @objc private func errorOccurredNotification(notification: NSNotification) {
        #if APP_EXTENSION
            if self.step.contains(.storageExceeded) { return }
            self.latestError = notification.userInfo?["text"] as? String
            if self.latestError == LocalString._storage_exceeded {
                insert(newStep: .storageExceeded)
            } else {
                insert(newStep: .sendingFinishedWithError)
            }
        #endif
    }

    @objc private func noErrorNotification() {
        #if APP_EXTENSION
        insert(newStep: .sendingFinishedSuccessfully)
        #endif
    }

    override func shouldDefaultObserveContentSizeChanges() -> Bool {
        return false
    }

    deinit {
        self.heightObservation = nil
        self.queueObservation = nil
    }

    override func caretMovedTo(_ offset: CGPoint) {
        self.stopInertia()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) { [weak self] in
            guard let self = self, let enclosingScroller = self.enclosingScroller else { return }
             // approx height and width of our text row
            let сaretBounds = CGSize(width: 100, height: 100)

            // vertical
            let offsetAreaInCell = CGRect(x: 0, y: offset.y - сaretBounds.height / 2, width: 1, height: сaretBounds.height)
            let offsetArea = self.view.convert(offsetAreaInCell, to: enclosingScroller.scroller)
            enclosingScroller.scroller.scrollRectToVisible(offsetArea, animated: true)
        }
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.htmlEditor.loadContentIfNeeded()
        super.webView(webView, didFinish: navigation)
    }

    override func addInlineAttachment(cid: String, name: String, data: Data) {
        guard viewModel.validateAttachmentsSize(withNew: data) == true else {
            DispatchQueue.main.async {
                self.latestErrorBanner?.remove(animated: true)
                self.latestErrorBanner = BannerView(appearance: .red, message: LocalString._the_total_attachment_size_cant_be_bigger_than_25mb, buttons: nil, offset: 8.0)
                #if !APP_EXTENSION
                UIApplication.shared.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
                #else
                // hackish way to get to UIApplication in Share extension
                (self.view.window?.next as? UIApplication)?.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
                #endif
            }

            self.htmlEditor.remove(embedImage: "cid:\(cid)")
            return
        }
        return super.addInlineAttachment(cid: cid, name: name, data: data)
    }

    func errorBannerToPresent() -> BannerView? {
        return self.latestErrorBanner
    }

// TODO: when refactoring ComposeViewController, place this stuff in a higher level ViewModel and Controller - ComposeContainer
#if APP_EXTENSION
    private let stepUpdateQueue = DispatchQueue(label: "me.proton.mail.step.update")
    private var latestError: String?
    private struct SendingStep: OptionSet {
        let rawValue: Int

        static var composing = SendingStep(rawValue: 1 << 0)
        static var composingCanceled = SendingStep(rawValue: 1 << 1)
        static var sendingStarted = SendingStep(rawValue: 1 << 2)
        static var sendingFinishedWithError = SendingStep(rawValue: 1 << 3)
        static var sendingFinishedSuccessfully = SendingStep(rawValue: 1 << 4)
        static var resultAcknowledged = SendingStep(rawValue: 1 << 5)
        static var queueIsEmpty = SendingStep(rawValue: 1 << 6)
        static var storageExceeded = SendingStep(rawValue: 1 << 7)
    }

    private var step: SendingStep = .composing
    private var stepAlert: UIAlertController? {
        didSet {
            DispatchQueue.main.async {
                guard self.presentedViewController != self.stepAlert else { return }
                self.presentedViewController?.dismiss(animated: false)
                if let alert = self.stepAlert {
                    self.present(alert, animated: false, completion: nil)
                }
            }
        }
    }

    private func contain(step: SendingStep) -> Bool {
        return stepUpdateQueue.sync {
            return self.step.contains(step)
        }
    }

    private func insert(newStep: SendingStep) {
        stepUpdateQueue.sync {
            guard !step.contains(newStep) else { return }
            self.step.insert(newStep)

            if newStep.contains(.storageExceeded) {
                let title = LocalString._storage_exceeded
                let message = LocalString._please_upgrade_plan
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(
                    .init(
                        title: LocalString._general_ok_action,
                        style: .default,
                        handler: {
                            [weak self] _ in
                            self?.dismissAnimation()
                        }
                    )
                )
                self.stepAlert = alert
                return
            }
            if self.step.contains(.resultAcknowledged) && self.step.contains(.queueIsEmpty) {
                self.dismissAnimation()
                return
            }
            if newStep.contains(.sendingFinishedSuccessfully) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
                    self?.insert(newStep: .resultAcknowledged)
                }
                let alert = UIAlertController(
                    title: "✅",
                    message: LocalString._message_sent_ok_desc,
                    preferredStyle: .alert
                )
                self.stepAlert = alert
                return
            }
            if newStep.contains(.sendingFinishedWithError) {
                if let latestError {
                    if latestError.isEmpty {
                        PMAssertionFailure("Attempting to show prompt with empty message")
                    } else {
                        let alert = UIAlertController(
                            title: "⚠️",
                            message: latestError,
                            preferredStyle: .alert
                        )
                        alert.addAction(
                            .init(
                                title: "Ok",
                                style: .default,
                                handler: {
                                    [weak self] _ in
                                    self?.step = .composing
                                }
                            )
                        )
                        self.stepAlert = alert
                    }
                } else {
                    PMAssertionFailure("Attempting to show prompt without message")
                }
                return
            }
        }
    }

    override func cancel() {
        guard dependencies.internetConnectionStatusProvider.status.isConnected else {
            // no point in waiting for queue to be empty, it won't be processed while we're offline
            dismissAnimation()
            return
        }

        stepUpdateQueue.sync {
            self.step = [.composingCanceled, .resultAcknowledged]
            let alert = UIAlertController(
                title: LocalString._closing_draft,
                message: LocalString._please_wait_in_foreground,
                preferredStyle: .alert
            )
            self.stepAlert = alert
        }
    }

    override func startSendingMessage() {
        guard dependencies.internetConnectionStatusProvider.status.isConnected else {
            SystemLogger.log(message: "Not connected", category: .sendMessage)

            let alert = UIAlertController(
                title: L10n.Compose.sendingWithShareExtensionWhileOfflineIsNotSupported,
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(.okAction())
            stepAlert = alert
            return
        }

        stepUpdateQueue.sync {
            self.step = .sendingStarted
            let alert = UIAlertController(
                title: LocalString._sending_message,
                message: LocalString._please_wait_in_foreground,
                preferredStyle: .alert
            )
            self.stepAlert = alert
        }

        super.startSendingMessage()
    }

    override func dismiss() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStepWhenTheQueueIsEmpty), name: .queueIsEmpty, object: nil)
    }

    @objc private func updateStepWhenTheQueueIsEmpty() {
        guard !contain(step: .queueIsEmpty) else { return }
        insert(newStep: .queueIsEmpty)
    }

    private func dismissAnimation() {
        dependencies.keyMaker.lockTheApp()

        SystemLogger.log(message: "Share extension is dismissing...", category: .appLifeCycle)

        dependencies.queueManager.unregisterHandler(for: viewModel.user.userID) {
            self.viewModel.user.container.reset()
            self.viewModel.user.container.globalContainer.reset()

            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    @objc
    func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
#endif
}
