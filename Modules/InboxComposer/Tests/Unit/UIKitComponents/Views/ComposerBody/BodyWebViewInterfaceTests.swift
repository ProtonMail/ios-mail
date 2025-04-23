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

@testable import InboxComposer
import Testing
import WebKit

@MainActor
final class BodyWebViewInterfaceTests {
    private let sut: BodyWebViewInterface
    private var delegate: WebViewDelegate!

    init() {
        self.sut = .init(webView: WKWebView(frame: .zero, configuration: WKWebViewConfiguration()))
    }

    // MARK: loadMessageBody

    @Test
    func testLoadMessageBodyBody_itLoadsTheGivenHtml() async {
        let dummyMessage = "<p>dummy message</p>"
        sut.loadMessageBody(dummyMessage)
        await waitForWebViewDidFinish(sut.webView)

        let html = await sut.readMesasgeBody()
        #expect(html == dummyMessage)
    }

    // MARK: insertImages

    @Test
    func testInsertImages_whenNoCursorExists_itInsertsTheImagesAtTheBeginning() async {
        sut.loadMessageBody("<p>initial message</p>")
        await waitForWebViewDidFinish(sut.webView)

        await sut.insertImages(["12345", "qwerty"])

        let html = await sut.readMesasgeBody()
        #expect(html == """
        <div><img src=\"cid:12345\"></div><br><div><img src=\"cid:qwerty\"></div><br><p>initial message</p>
        """)
    }

    @Test
    func testInsertImages_whenCursorExists_itInsertsTheImagesAtTheCursorPosition() async throws {
        sut.loadMessageBody("<p>first part</p><p>second part</p>")
        await waitForWebViewDidFinish(sut.webView)

        try await setCursorAfter(text: "first part")
        await sut.insertImages(["12345"])

        let html = await sut.readMesasgeBody()
        #expect(html == "<p>first part</p><div><img src=\"cid:12345\"></div><br><p>second part</p>")
    }
}

// MARK: Helpers

private extension BodyWebViewInterfaceTests {

    private func waitForWebViewDidFinish(_ webView: WKWebView) async {
        await withCheckedContinuation { continuation in
            delegate = WebViewDelegate(continuation)
            webView.navigationDelegate = delegate
        }
    }

    private func setCursorAfter(text: String) async throws {
        let script = """
            (function() {
                const editor = document.getElementById('editor');
                const textNode = Array.from(editor.childNodes).find(node => node.textContent.includes('\(text)'));
                if (!textNode) return false;
                
                const range = document.createRange();
                range.setStartAfter(textNode);
                range.collapse(true);
                
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
                
                editor.focus();
                return true;
            })()
        """
        try await sut.webView.evaluateJavaScript(script)
    }
}

private class WebViewDelegate: NSObject, WKNavigationDelegate {
    let continuation: CheckedContinuation<Void, Never>
    init(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation.resume()
    }
}
