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
import InboxTesting
import SwiftUI
import Testing
import WebKit

@MainActor
final class MessageBodyReaderViewTests {
    private let urlOpenerSpy = EnvironmentURLOpenerSpy()

    private lazy var sut = MessageBodyReaderView(
        bodyContentHeight: .constant(.zero),
        body: .init(
            rawBody: "<html>dummy</html>",
            options: .init(),
            embeddedImageProvider: EmbeddedImageProviderSpy()
        )
    )

    private lazy var coordinator: MessageBodyReaderView.Coordinator = {
        let coordinator = sut.makeCoordinator()
        coordinator.urlOpener = urlOpenerSpy
        return coordinator
    }()

    @Test
    func test_WhenLinkInsideWebViewIsTapped_ItOpensURL() async {
        let result = await coordinator.webView(.init(), decidePolicyFor: NavigationActionStub(navigationType: .linkActivated, url: protonURL))

        #expect(result == .cancel)
        #expect(urlOpenerSpy.callAsFunctionInvokedWithURL == [protonURL])
    }

    @Test
    func test_WhenReloadNavigationIsTriggered_ItDoesNotOpenURL() async {
        let result = await coordinator.webView(.init(), decidePolicyFor: NavigationActionStub(navigationType: .reload, url: protonURL))

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
