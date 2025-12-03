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

import Testing
import WebKit

@testable import ProtonMail

@MainActor
final class WebViewPrintingTransactionTests {
    @Test
    func insertsHeaderOnlyForTheDurationOfTheTransaction() async throws {
        let webView = WKWebView()
        let transaction = WebViewPrintingTransaction(message: .testData(), attachments: [], webView: webView)

        webView.loadHTMLString("<div>Hello, world!</div>", baseURL: nil)
        let expectedContentBefore = "<html><head></head><body><div>Hello, world!</div></body></html>"
        try await waitUntilContentIsLoaded(in: webView, expectedContent: expectedContentBefore)

        try await transaction.perform { _, _ in
            let contentDuring = await webView.contents()
            #expect(contentDuring.contains(/<html><head><\/head><body><img id="[^"]+" src="data:image\/png;base64,[^"]+"><div>Hello, world!<\/div><\/body><\/html>/))
        }

        let contentAfter = await webView.contents()
        #expect(contentAfter == expectedContentBefore)
    }

    private func waitUntilContentIsLoaded(in webView: WKWebView, expectedContent: String) async throws {
        let maxRetries = 50

        for _ in 0..<maxRetries {
            if await webView.contents() == expectedContent {
                return
            } else {
                try await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}

private extension WKWebView {
    func contents() async -> String {
        let script = """
            function getHTMLContent() {
                return new Promise(function(resolve) {
                    if (document.readyState === 'complete') {
                        resolve(document.documentElement.outerHTML);
                    } else {
                        window.addEventListener('load', function() {
                            resolve(document.documentElement.outerHTML);
                        });
                    }
                });
            }

            return await getHTMLContent();
            """

        return try! #require(await callAsyncJavaScript(script, contentWorld: .defaultClient) as? String)
    }
}
