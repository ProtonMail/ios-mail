// Copyright (c) 2021 Proton AG
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

import ProtonCoreTestingToolkitUnitTestsServices
import WebKit
import XCTest

@testable import ProtonMail

class NewMessageBodyViewModelTests: XCTestCase {
    private var sut: NewMessageBodyViewModel!
    private var newMessageBodyViewModelDelegateMock: MockNewMessageBodyViewModelDelegate!
    private var apiServiceMock: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let connectionMonitor = MockConnectionMonitor()
        let internetConnectionStatusProviderMock = InternetConnectionStatusProvider(connectionMonitor: connectionMonitor)
        apiServiceMock = .init()
        let imageProxy = ImageProxy(
            dependencies: .init(apiService: apiServiceMock, imageCache: MockImageProxyCacheProtocol())
        )
        sut = NewMessageBodyViewModel(
            spamType: nil,
            internetStatusProvider: internetConnectionStatusProviderMock,
            linkConfirmation: .openAtWill,
            userKeys: .init(privateKeys: [], addressesPrivateKeys: [], mailboxPassphrase: .init(value: "passphrase")),
            imageProxy: imageProxy
        )
        newMessageBodyViewModelDelegateMock = MockNewMessageBodyViewModelDelegate()
        sut.delegate = newMessageBodyViewModelDelegateMock
    }

    override func tearDown() {
        sut = nil
        newMessageBodyViewModelDelegateMock = nil

        super.tearDown()
    }

    func testPlaceholderContent() {
        XCTAssertEqual(sut.currentMessageRenderStyle, .dark)
        let meta = "<meta name=\"viewport\" content=\"width=device-width\">"
        let expected = """
                            <html><head>\(meta)<style type='text/css'>
                            \(WebContents.css)</style>
                            </head></html>
                         """
        XCTAssertEqual(sut.placeholderContent, expected)

        sut.update(renderStyle: .lightOnly)
        XCTAssertEqual(sut.currentMessageRenderStyle, .lightOnly)
        let expected1 = """
                            <html><head>\(meta)<style type='text/css'>
                            \(WebContents.cssLightModeOnly)</style>
                            </head></html>
                         """
        XCTAssertEqual(sut.placeholderContent, expected1)
    }

    func testGetWebViewConfig() {
        XCTAssertEqual(sut.webViewConfig.dataDetectorTypes, [.phoneNumber, .link])
    }

    @MainActor
    func testWebViewConfig_blocksEmbeddedJavaScript() async throws {
        let bodyWithSUTConfig = try await loadMessageWithJavaScript(configuration: sut.webViewConfig)
        XCTAssertEqual(bodyWithSUTConfig, "original content")

        let sanityCheckBody = try await loadMessageWithJavaScript(configuration: nil)
        XCTAssertEqual(sanityCheckBody, "modified by javascript")
    }

    @MainActor
    private func loadMessageWithJavaScript(configuration: WKWebViewConfiguration?) async throws -> String {
        let webView = configuration.map { WKWebView(frame: .zero, configuration: $0) } ?? WKWebView(frame: .zero)

        let delegate = NavigationDelegate()
        webView.navigationDelegate = delegate

        let html = """
<!DOCTYPE html>
<html lang="en">

<body>
    original content

    <script>
        document.body.innerHTML = "modified by javascript";
    </script>
</body>

</html>
"""
        webView.loadHTMLString(html, baseURL: nil)

        await delegate.waitForNavigationToFinish()

        let scriptOutput = try await webView.evaluateJavaScript("document.body.innerHTML")
        return try XCTUnwrap(scriptOutput as? String).trim()
    }
}

private class NavigationDelegate: NSObject, WKNavigationDelegate {
    private var pendingContinuation: CheckedContinuation<Void, Never>?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pendingContinuation?.resume()
    }

    func waitForNavigationToFinish() async {
        return await withCheckedContinuation { continuation in
            pendingContinuation = continuation
        }
    }
}
