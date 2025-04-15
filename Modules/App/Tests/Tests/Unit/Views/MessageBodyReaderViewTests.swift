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
import SwiftUI
import Testing
import WebKit

@MainActor
class MessageBodyReaderViewTests {
    var sut: MessageBodyReaderView!
    private var urlOpenerSpy: EnvironmentURLOpenerSpy!

    init() {
        urlOpenerSpy = .init()
        sut = MessageBodyReaderView(
            bodyContentHeight: .constant(.zero),
            body: .init(
                rawBody: "<html>dummy</html>",
                options: .init(
                    showBlockQuote: true,
                    hideRemoteImages: .none,
                    hideEmbeddedImages: .none
                ),
                embeddedImageProvider: EmbeddedImageProviderSpy()
            ),
            urlOpener: urlOpenerSpy,
            htmlLoaded: {}
        )
    }

    deinit {
        urlOpenerSpy = nil
        sut = nil
    }

    @Test
    func test_WhenLinkInsideWebViewIsTapped_ItOpensURL() async {
        let result = await sut.webView(navigation: .init(navigationType: .linkActivated, url: protonURL))

        #expect(result == .cancel)
        #expect(urlOpenerSpy.callAsFunctionInvokedWithURL == [protonURL])
    }

    @Test
    func test_WhenReloadNavigationIsTriggered_ItDoesNotOpenURL() async {
        let result = await sut.webView(navigation: .init(navigationType: .reload, url: protonURL))

        #expect(result == .allow)
        #expect(urlOpenerSpy.callAsFunctionInvokedWithURL.isEmpty == true)
    }

    @Test
    func test_WhenUpdateUIViewIsCalledByTheSystem_ItReloadsWebView() throws {
        let webViewSpy = WKWebViewSpy()

        #expect(webViewSpy.loadHTMLStringCalls.count == 0)

        sut.updateUIView(webViewSpy)

        #expect(webViewSpy.loadHTMLStringCalls.count == 1)

        let arguments = try #require(webViewSpy.loadHTMLStringCalls.last)

        #expect(arguments.html == "<html>dummy</html>")
        #expect(arguments.baseURL == nil)
    }

    private var protonURL: URL {
        URL(string: "https://account.proton.me").unsafelyUnwrapped
    }
}

private extension MessageBodyReaderView {
    func webView(navigation: NavigationActionStub) async -> WKNavigationActionPolicy {
        let coordinator = makeCoordinator()
        let result = await coordinator.webView(WKWebView(), decidePolicyFor: navigation)

        return result
    }
}

private class EnvironmentURLOpenerSpy: URLOpenerProtocol {
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

private class WKWebViewSpy: WKWebView {

    private(set) var loadHTMLStringCalls: [(html: String, baseURL: URL?)] = []

    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        loadHTMLStringCalls.append((string, baseURL))

        return nil
    }

}
