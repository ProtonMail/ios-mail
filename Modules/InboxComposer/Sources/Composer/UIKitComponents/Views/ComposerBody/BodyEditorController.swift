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

final class BodyEditorController: UIViewController {

    enum Event {
        case onStartEditing
        case onBodyChange(body: String)
        case onCursorPositionChange(position: CGPoint)
    }

    private let htmlInterface: BodyWebViewInterface
    private var webView: WKWebView { htmlInterface.webView }
    private var heightConstraint: NSLayoutConstraint!
    private lazy var initialFocusState = BodyInitialFocusState { [weak self] in
        await self?.htmlInterface.setFocus()
    }
    var onEvent: ((Event) -> Void)?

    init(embeddedImageProvider: EmbeddedImageProvider) {
        self.htmlInterface = BodyWebViewInterface(webView: SubviewFactory.webView(embeddedImageProvider: embeddedImageProvider))
        super.init(nibName: nil, bundle: nil)
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
            heightConstraint
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
                    guard let body = await htmlInterface.readMesasgeBody() else { return }
                    onEvent?(.onBodyChange(body: body))
                }
            case .onCursorPositionChange(let position):
                onEvent?(.onCursorPositionChange(position: position))
            }
        }
    }

    func setBodyInitialFocus() {
        Task { await initialFocusState.setFocusWhenLoaded() }
    }

    func updateBody(html body: String) {
        htmlInterface.loadMessageBody(body)
    }

    func handleBodyAction(action: ComposerBodyAction) {
        switch action {
        case .insertInlineImages(let cids):
            Task {
                await htmlInterface.insertImages(cids)
            }
        }
    }
}

extension BodyEditorController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { await initialFocusState.bodyWasLoaded() }
    }
}

extension BodyEditorController {

    enum SubviewFactory {

        static func webView(embeddedImageProvider: EmbeddedImageProvider) -> WKWebView {
            let config = WKWebViewConfiguration()
            config.dataDetectorTypes = [.link]
            config.setURLSchemeHandler(
                CIDSchemeHandler(embeddedImageProvider: embeddedImageProvider),
                forURLScheme: CIDSchemeHandler.handlerScheme
            )

            let backgroundColor = DS.Color.Background.norm.toDynamicUIColor
            let webView = WKWebViewWithNoAccessoryView(frame: .zero, configuration: config)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false

            webView.isOpaque = false
            webView.backgroundColor = backgroundColor
            webView.scrollView.backgroundColor = backgroundColor
            webView.scrollView.contentInsetAdjustmentBehavior = .never
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
    private let setFocusAction: (() async -> Void)

    init(setFocusAction: @escaping (() async -> Void)) {
        self.setFocusAction = setFocusAction
    }

    private func moveToNextState() async {
        guard state != .done else { return }
        switch state {
        case .bodyNotLoaded:
            state = .bodyLoaded
        case .bodyLoaded:
            if shouldSetFocusWhenLoaded {
                await setFocusAction()
            }
            state = .done
        case .done:
            break
        }
        await moveToNextState()
    }

    func setFocusWhenLoaded() {
        shouldSetFocusWhenLoaded = true
    }

    func bodyWasLoaded() async {
        await moveToNextState()
    }
}
