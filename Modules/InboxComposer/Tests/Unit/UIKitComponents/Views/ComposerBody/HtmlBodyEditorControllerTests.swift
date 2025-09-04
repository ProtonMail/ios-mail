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

@testable import InboxComposer
import InboxCore
import Testing
import WebKit

@MainActor
final class HtmlBodyEditorControllerTests {
    private var sut: HtmlBodyEditorController!
    private var mockInterface: MockHtmlBodyWebViewInterface!

    init() {
        self.mockInterface = MockHtmlBodyWebViewInterface()
        sut = makeSUT(htmlBodyWebViewInterface: mockInterface)
    }

    // MARK: updateBody

    @Test
    func updateBody_itShouldCallLoadMessageBody() async {
        triggerViewDidLoad()
        sut.updateBody("hello")
        #expect(mockInterface.loadedBody == "hello")
    }

    // MARK: HtmlBodyWebViewInterfaceProtocol onEvent(.onTextPasted)

    @Test
    func onEventTextPasted_sanitizesAndCallsInsertText() async {
        triggerViewDidLoad()
        let raw = "<span style=\"color:red;\">Hello</span>"
        mockInterface.onEvent?(.onTextPasted(text: raw))

        await Task.yield()
        #expect(mockInterface.insertedTexts == ["\"<span >Hello<\\/span>\""])
    }
}

extension HtmlBodyEditorControllerTests {

    private func makeSUT(htmlBodyWebViewInterface: HtmlBodyWebViewInterfaceProtocol) -> HtmlBodyEditorController {
        let mockMemory = MockMemoryPressureHandler()
        let sut = HtmlBodyEditorController(
            htmlInterface: htmlBodyWebViewInterface,
            webViewMemoryPressureHandler: mockMemory
        )
        return sut
    }

    private func triggerViewDidLoad() {
        _ = sut.view
    }
}

private final class MockHtmlBodyWebViewInterface: HtmlBodyWebViewInterfaceProtocol {
    let webView: WKWebView = WKWebView()
    var onEvent: ((HtmlBodyWebViewInterface.Event) -> Void)?

    private(set) var loadedBody: String = ""
    private(set) var insertedTexts: [String] = []

    func loadMessageBody(_ body: String) {
        loadedBody = body
    }

    func setFocus() async {}

    func readMesasgeBody() async -> String? { nil }

    func insertText(_ text: String) async {
        insertedTexts.append(text)
    }

    func insertImages(_ contentIds: [String]) async {}

    func removeImage(containing cid: String) async {}
}

private final class MockMemoryPressureHandler: WebViewMemoryPressureProtocol {
    private var reload: (() -> Void)?
    func contentReload(_ contentReload: @escaping () -> Void) { reload = contentReload }
    func markWebContentProcessTerminated() { reload?() }
}
