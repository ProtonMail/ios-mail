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

import InboxDesignSystem
import UIKit
import WebKit

enum BodyEditorEvent {
    case onStartEditing
    case onBodyChange(body: String)
}

final class BodyEditorController: UIViewController {
    private let htmlInterface: BodyWebViewInterface // = BodyWebViewInterface(webView: SubviewFactory.webView)
    private var webView: WKWebView { htmlInterface.webView }
    private var heightConstraint: NSLayoutConstraint!

    var onEvent: ((BodyEditorEvent) -> Void)?

    init(embeddedImageProvider: EmbeddedImageProvider) {
        self.htmlInterface = BodyWebViewInterface(webView: SubviewFactory.webView(embeddedImageProvider: embeddedImageProvider))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
        setUpCallback()
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

    private func setUpCallback() {
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
            }
        }
    }

    func updateBody(html body: String) {
        htmlInterface.loadMessageBody(body)
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

            let backgroundColor = UIColor(DS.Color.Background.norm)
            let webView = WKWebView(frame: .zero, configuration: config)
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
