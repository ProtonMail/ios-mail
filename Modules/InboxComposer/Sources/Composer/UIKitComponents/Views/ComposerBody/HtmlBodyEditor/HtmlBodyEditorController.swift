// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxCore
import InboxDesignSystem
import UIKit
import WebKit

final class HtmlBodyEditorController: UIViewController, BodyEditor {
    private let htmlInterface: HtmlBodyWebViewInterfaceProtocol
    private var webView: WKWebView { htmlInterface.webView }
    private var heightConstraint: NSLayoutConstraint!
    private lazy var initialFocusState = BodyInitialFocusState { [weak self] in
        await self?.htmlInterface.setFocus()
    }
    private let webViewMemoryPressureHandler: WebViewMemoryPressureProtocol
    var onEvent: ((BodyEditorEvent) -> Void)?

    init(
        imageProxy: ImageProxy,
        webViewMemoryPressureHandler: WebViewMemoryPressureProtocol = WebViewMemoryPressureHandler(loggerCategory: .composer)
    ) {
        self.htmlInterface = HtmlBodyWebViewInterface(webView: SubviewFactory.webView(imageProxy: imageProxy))
        self.webViewMemoryPressureHandler = webViewMemoryPressureHandler
        super.init(nibName: nil, bundle: nil)
        webViewMemoryPressureHandler.contentReload { [weak self] in
            self?.onEvent?(.onReloadAfterMemoryPressure)
        }
    }

    /// Used for testing
    init(
        htmlInterface: HtmlBodyWebViewInterfaceProtocol,
        webViewMemoryPressureHandler: WebViewMemoryPressureProtocol
    ) {
        self.htmlInterface = htmlInterface
        self.webViewMemoryPressureHandler = webViewMemoryPressureHandler
        super.init(nibName: nil, bundle: nil)
        webViewMemoryPressureHandler.contentReload { [weak self] in
            self?.onEvent?(.onReloadAfterMemoryPressure)
        }
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
        setUpCallbacks()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
    }

    private func setUpConstraints() {
        let initialHeight = 150.0
        heightConstraint = webView.heightAnchor.constraint(greaterThanOrEqualToConstant: initialHeight)
        let margin = DS.Spacing.large
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin),
            heightConstraint,
        ])
    }

    private func setUpCallbacks() {
        webView.navigationDelegate = self

        htmlInterface.onEvent = { [weak self] htmlEvent in
            guard let self else { return }
            switch htmlEvent {
            case .onContentHeightChange(let height):
                DispatchQueue.main.async { [weak self] in
                    self?.heightConstraint.constant = height
                }
            case .onEditorFocus:
                onEvent?(.onStartEditing)
            case .onEditorChange:
                Task { [weak self] in
                    guard let self else { return }
                    guard let body = await htmlInterface.readMessageBody() else { return }
                    onEvent?(.onBodyChange(body: body))
                }
            case .onCursorPositionChange(let position):
                onEvent?(.onCursorPositionChange(position: position))
            case .onInlineImageRemoved(let cid):
                onEvent?(.onInlineImageRemoved(cid: cid))
            case .onInlineImageTapped(let cid, let imageRect):
                showInlineImageMenu(cid: cid, imageRect: imageRect)
            case .onImagePasted(let imageData):
                guard let image = UIImage(data: imageData) else {
                    AppLogger.log(message: "pasted data is not an image", category: .composer, isError: true)
                    return
                }
                onEvent?(.onImagePasted(image: image))
            case .onTextPasted(let text):
                let styleStrippedText = HtmlSanitizer.removeStyleAttribute(html: text)
                let sanitisedText = HtmlSanitizer.applyStringLiteralEscapingRules(html: styleStrippedText)
                handleBodyAction(.insertText(text: sanitisedText))
            }
        }
    }

    func setBodyInitialFocus() {
        Task { await initialFocusState.setFocusWhenLoaded() }
    }

    func updateBody(_ body: String) async {
        await htmlInterface.loadMessageBody(body, clearImageCacheFirst: false)
    }

    func handleBodyAction(_ action: ComposerBodyAction) {
        switch action {
        case .insertText(let text):
            Task { await htmlInterface.insertText(text) }
        case .insertInlineImages(let cids):
            Task { await htmlInterface.insertImages(cids) }
        case .removeInlineImage(let cid):
            Task { await htmlInterface.removeImage(containing: cid) }
        case .reloadBody(let html, let clearImageCacheFirst):
            Task { await htmlInterface.loadMessageBody(html, clearImageCacheFirst: clearImageCacheFirst) }
        }
    }

    private func showInlineImageMenu(cid: String, imageRect: CGRect) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let option1 = UIAlertAction(title: L10n.Attachments.sendAsAttachment.string, style: .default) { [weak self] _ in
            self?.onEvent?(.onInlineImageDispositionChangeRequested(cid: cid))
        }
        let option2 = UIAlertAction(title: L10n.Attachments.removeAttachment.string, style: .default) { [weak self] _ in
            self?.onEvent?(.onInlineImageRemovalRequested(cid: cid))
        }
        let cancel = UIAlertAction(title: CommonL10n.cancel.string, style: .cancel)

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = webView
            popover.sourceRect = imageRect
        }

        alertController.addAction(option1)
        alertController.addAction(option2)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension HtmlBodyEditorController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { await initialFocusState.bodyWasLoaded() }
        Task { await htmlInterface.logHtmlHealthCheck(tag: "webView.didFinish") }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webViewMemoryPressureHandler.markWebContentProcessTerminated()
    }
}

extension HtmlBodyEditorController {

    enum SubviewFactory {

        static func webView(imageProxy: ImageProxy) -> WKWebView {
            let config = WKWebViewConfiguration.default(
                handler: UniversalSchemeHandler.init(imageProxy: imageProxy, imagePolicy: .safe)
            )

            // using a custom cache to be able to flush it when necessary (e.g. failed inline image upload)
            config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

            let webView = WKWebView.default(configuration: config)
            webView.translatesAutoresizingMaskIntoConstraints = false
            return webView
        }
    }
}

private class WKWebViewWithNoAccessoryView: WKWebView {

    override var inputAccessoryView: UIView? {
        return nil
    }
}

private final actor BodyInitialFocusState {
    enum State {
        case bodyNotLoaded
        case bodyLoaded
        case done
    }

    private var state: State = .bodyNotLoaded
    private var shouldSetFocusWhenLoaded: Bool = false
    private var focusHasBeenSet: Bool = false
    private let setFocusAction: (() async -> Void)

    init(setFocusAction: @escaping (() async -> Void)) {
        self.setFocusAction = setFocusAction
    }

    func setFocusWhenLoaded() async {
        switch state {
        case .bodyNotLoaded:
            shouldSetFocusWhenLoaded = true
        case .bodyLoaded, .done:
            await setFocus()
        }
    }

    func bodyWasLoaded() async {
        await moveToNextState()
    }

    private func moveToNextState() async {
        guard state != .done else { return }
        switch state {
        case .bodyNotLoaded:
            state = .bodyLoaded
        case .bodyLoaded:
            if shouldSetFocusWhenLoaded {
                await setFocus()
            }
            state = .done
        case .done:
            break
        }
        await moveToNextState()
    }

    private func setFocus() async {
        guard !focusHasBeenSet else { return }
        focusHasBeenSet = true
        await setFocusAction()
    }
}
