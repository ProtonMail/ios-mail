// Copyright (c) 2025 Proton Technologies AG
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

import SnapshotTesting
import SwiftUI
import WebKit
import XCTest
import proton_app_uniffi

@testable import InboxEmailLayoutTesting

@MainActor
final class MailingSnapshotTests: XCTestCase {
    let mailings: [String] = [
        "google-dec-2025"
    ]

    func testMailingWithLocalResources() {
        mailings.forEach { name in
            let assetsPath = TestAssetLoader.mailingAssetsPath(named: name)
            let schemeHandler = LocalResourceSchemeHandler(assetsPath: assetsPath)

            let webVC = WebViewController(schemeHandler: schemeHandler)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 1500))
            window.isHidden = false
            window.rootViewController = webVC

            let rawHTML = TestAssetLoader.mailingHTML(named: name)
            let processedHTML = preProcessedHTML(rawHTML: rawHTML)

            webVC.loadHTML(html: processedHTML)

            assertSnapshot(
                of: webVC,
                as: .wait(for: 1.0, on: .image),
                named: name
            )
        }
    }
}

private final class WebViewController: UIViewController, WKNavigationDelegate {
    private let schemeHandler: WKURLSchemeHandler?

    init(schemeHandler: WKURLSchemeHandler? = nil) {
        self.schemeHandler = schemeHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()

        if let schemeHandler = schemeHandler {
            configuration.setURLSchemeHandler(schemeHandler, forURLScheme: "proton-https")
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func loadHTML(html: String) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func setupView() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

/// WKURLSchemeHandler that intercepts proton-https:// URLs and serves local files
private final class LocalResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    private let assetsPath: URL

    init(assetsPath: URL) {
        self.assetsPath = assetsPath
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
            let filename = url.host ?? url.path.components(separatedBy: "/").last,
            !filename.isEmpty
        else {
            urlSchemeTask.didFailWithError(NSError(domain: "LocalResourceSchemeHandler", code: 404))
            return
        }

        let fileURL = assetsPath.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(NSError(domain: "LocalResourceSchemeHandler", code: 404))
            return
        }

        let mimeType: String
        switch fileURL.pathExtension.lowercased() {
        case "png": mimeType = "image/png"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "gif": mimeType = "image/gif"
        case "svg": mimeType = "image/svg+xml"
        case "webp": mimeType = "image/webp"
        default: mimeType = "application/octet-stream"
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: nil
        )

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

private enum TestAssetLoader {
    private static let resourceBundle: Bundle = Bundle.module

    static func mailingAssetsPath(named name: String) -> URL {
        guard let resourceURL = resourceBundle.resourceURL else {
            fatalError("Unable to find test resource bundle")
        }

        return resourceURL
    }

    static func mailingHTML(named name: String) -> String {
        guard let htmlPath = resourceBundle.path(forResource: "\(name)-index", ofType: "html") else {
            fatalError("Unable to find \(name)-index.html in resource bundle")
        }

        return try! String(contentsOfFile: htmlPath, encoding: .utf8)
    }
}
