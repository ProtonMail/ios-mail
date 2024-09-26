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

    func test_whenLinkInsideWebViewIsTappedItOpensURL() async {
        let urlOpenerSpy = URLOpenerSpy()
        let sut = MessageBodyReaderView(bodyContentHeight: .constant(.zero), html: .notUsed, urlOpener: urlOpenerSpy)
        let coordinator = await sut.makeCoordinator()
        let stubbedURL = URL(string: "https://account.proton.me").unsafelyUnwrapped
        let webViewLinkAction = NavigationActionStub(navigationType: .linkActivated, url: stubbedURL)
        let result = await coordinator.webView(WKWebView(), decidePolicyFor: webViewLinkAction)
        XCTAssertEqual(result, .allow)
        XCTAssertEqual(urlOpenerSpy.callAsFunctionInvokedWithURL, [stubbedURL])
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
