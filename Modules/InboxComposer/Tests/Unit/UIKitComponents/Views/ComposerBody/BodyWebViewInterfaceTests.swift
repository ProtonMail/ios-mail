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

import Testing
import WebKit

@testable import InboxComposer

@MainActor
final class BodyWebViewInterfaceTests {
    private let sut: HtmlBodyWebViewInterface
    private var mockWebsiteDataStore: MockWebsiteDataStore!
    private var delegate: WebViewDelegate!
    private let dummyMessage = "<p>dummy message</p>"

    init() {
        self.mockWebsiteDataStore = .init()
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        self.sut = .init(webView: webView, websiteDataStore: mockWebsiteDataStore)
    }

    // MARK: loadMessageBody

    @Test
    func testLoadMessageBodyBody_whioutClearingCache_itLoadsTheGivenHtml() async {
        await sut.loadMessageBody(dummyMessage, clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        let html = await sut.readMessageBody()
        #expect(html == dummyMessage)
        #expect(mockWebsiteDataStore.removeDataCalled == false)
    }

    @Test
    func testLoadMessageBody_whenClearCacheFirst_itClearsCacheAndLoadsTheGivenHtml() async {
        await sut.loadMessageBody(dummyMessage, clearImageCacheFirst: true)
        await waitForWebViewDidFinish(sut.webView)

        let html = await sut.readMessageBody()
        #expect(html == dummyMessage)
        #expect(mockWebsiteDataStore.removeDataCalled == true)
    }

    // MARK: insertImages

    @Test
    func testInsertImages_whenNoCursorExists_itInsertsTheImagesAtTheBeginning() async {
        await sut.loadMessageBody("<p>initial message</p>", clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        await sut.insertImages(["12345", "qwerty"])

        let html = await sut.readMessageBody()
        #expect(
            html == """
                <img src="cid:12345"><br><img src="cid:qwerty"><br><p>initial message</p>
                """)
    }

    @Test
    func testInsertImages_whenCursorExists_itInsertsTheImagesAtTheCursorPosition() async throws {
        await sut.loadMessageBody("<p>first part</p><p>second part</p>", clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        try await setCursorAfter(text: "first part")
        await sut.insertImages(["12345"])

        let html = await sut.readMessageBody()
        #expect(html == "<p>first part</p><img src=\"cid:12345\"><br><p>second part</p>")
    }

    // MARK: removeImage(containing:)

    @Test
    func testRemoveImage_whenThereIsCIDMatch_itRemovesTheImgObject() async {
        await sut.loadMessageBody("<p>hello<img src=\"cid:12345\"><br></p>", clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        await sut.removeImage(containing: "12345")

        let html = await sut.readMessageBody()
        #expect(
            html == """
                <p>hello<br></p>
                """)
    }

    @Test
    func testRemoveImage_whenThereIsPartialCIDMatch_itDoesNotRemoveTheImage() async {
        await sut.loadMessageBody("<p>hello<img src=\"cid:123456789\"><br></p>", clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        await sut.removeImage(containing: "12345")

        let html = await sut.readMessageBody()
        #expect(
            html == """
                <p>hello<img src="cid:123456789"><br></p>
                """)
    }

    @Test
    func testRemoveImage_whenCIDDoesNotExist_itDoesNotModifyTheHTML() async {
        await sut.loadMessageBody("<p>hello<img src=\"cid:12345\"><br></p>", clearImageCacheFirst: false)
        await waitForWebViewDidFinish(sut.webView)

        await sut.removeImage(containing: "12567")

        let html = await sut.readMessageBody()
        #expect(
            html == """
                <p>hello<img src="cid:12345"><br></p>
                """)
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

private final class MockWebsiteDataStore: WebsiteDataStoreType {
    private(set) var removeDataCalled = false

    func removeData(ofTypes websiteDataTypes: Set<String>, modifiedSince date: Date) async {
        removeDataCalled = true
    }
}
