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

@testable import ProtonMail
import XCTest
import WebKit

class MessageBodyReaderViewTests: XCTestCase {

    var sut: MessageBodyReaderView!
    private var urlOpenerSpy: URLOpenerSpy!

    override func setUp() {
        super.setUp()

        urlOpenerSpy = .init()
        sut = MessageBodyReaderView(
            bodyContentHeight: .constant(.zero),
            messageBody: .init(body: .notUsed, embeddedImageProvider: EmbeddedImageProviderSpy()),
            urlOpener: urlOpenerSpy
        ) {}
    }

    override func tearDown() {
        urlOpenerSpy = nil
        sut = nil

        super.tearDown()
    }

    func test_WhenLinkInsideWebViewIsTapped_ItOpensURL() async {
        let result = await sut.webView(navigation: .init(navigationType: .linkActivated, url: protonURL))

        XCTAssertEqual(result, .cancel)
        XCTAssertEqual(urlOpenerSpy.callAsFunctionInvokedWithURL, [protonURL])
    }

    func test_WhenReloadNavigationIsTriggered_ItDoesNotOpenURL() async {
        let result = await sut.webView(navigation: .init(navigationType: .reload, url: protonURL))

        XCTAssertEqual(result, .allow)
        XCTAssertTrue(urlOpenerSpy.callAsFunctionInvokedWithURL.isEmpty)
    }

    private var protonURL: URL {
        URL(string: "https://account.proton.me").unsafelyUnwrapped
    }
}

private extension MessageBodyReaderView {
    func webView(navigation: NavigationActionStub) async -> WKNavigationActionPolicy {
        let coordinator = await makeCoordinator()
        let result = await coordinator.webView(WKWebView(), decidePolicyFor: navigation)

        return result
    }
}

private class URLOpenerSpy: URLOpenerProtocol {
    private(set) var callAsFunctionInvokedWithURL: [URL] = []

    func callAsFunction(_ url: URL) {
        callAsFunctionInvokedWithURL.append(url)
    }
}

private class NavigationActionStub: WKNavigationAction {
    private let _navigationType: WKNavigationType
    private let url: URL

    init(navigationType: WKNavigationType, url: URL) {
        _navigationType = navigationType
        self.url = url
    }

    override var navigationType: WKNavigationType {
        _navigationType
    }

    override var request: URLRequest {
        URLRequest(url: url)
    }
}
