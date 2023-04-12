// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_TestingToolkit

class MockComposerSchemeHandler: ComposerSchemeHandler {}

class MockNavigationDelegate: NSObject, WKNavigationDelegate {
    var didFinishIsCalled: (() -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishIsCalled?()
    }
}

final class HtmlEditorBehaviourTests: XCTestCase {

    var container: UIViewController!
    var webView: WKWebView!
    var urlHandler: MockComposerSchemeHandler!
    var apiMock: APIServiceMock!
    var navigationDelegateMock: MockNavigationDelegate!
    var sut: HtmlEditorBehaviour!


    override func setUp() {
        super.setUp()
        navigationDelegateMock = .init()
        container = .init()
        apiMock = .init()
        urlHandler = .init(imageProxy: .init(dependencies: .init(apiService: apiMock)))
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(
            urlHandler,
            forURLScheme: HTTPRequestSecureLoader.ProtonScheme.http.rawValue
        )
        config.setURLSchemeHandler(
            urlHandler,
            forURLScheme: HTTPRequestSecureLoader.ProtonScheme.https.rawValue
        )
        config.setURLSchemeHandler(
            urlHandler,
            forURLScheme: HTTPRequestSecureLoader.ProtonScheme.noProtocol.rawValue
        )
        webView = PMWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = navigationDelegateMock
        container.view.addSubview(webView)
        webView.fillSuperview()
        container.loadViewIfNeeded()

        sut = .init()
    }

    override func tearDown() {
        super.tearDown()
        container = nil
        webView = nil
        sut = nil
        urlHandler = nil
        apiMock = nil
    }

    func testSetupWebView() {
        let e = expectation(description: "Closure is called")
        navigationDelegateMock.didFinishIsCalled = {
            e.fulfill()
        }
        sut.setup(webView: webView)

        XCTAssertEqual(webView.url, URL(string: "about:blank"))

        waitForExpectations(timeout: 1)
    }

    func testLoadHtmlContent_dataForDraftWithoutProtonPrefix() throws {
        let e = expectation(description: "Closure is called")
        navigationDelegateMock.didFinishIsCalled = {
            self.sut.loadContentIfNeeded()
            e.fulfill()
        }
        sut.setup(webView: webView)
        waitForExpectations(timeout: 1)

        XCTAssertTrue(sut.isEditorLoaded)

        let e2 = expectation(description: "Content is loaded")
        let webContent = WebContents(
            body: Self.testContentWithRemoteImage,
            remoteContentMode: .allowed,
            messageDisplayMode: .collapsed
        )

        // Load the html
        sut.setHtml(body: webContent) { result in
            switch result {
            case .success():
                break
            case .failure(_):
                XCTFail("Should not reach here.")
            }
            e2.fulfill()
        }
        waitForExpectations(timeout: 3)

        // Check loaded html in the webview
        let e3 = expectation(description: "Get raw html from editor")
        var html: String?
        getInnerHtmlOfEditor { result in
            html = result
            e3.fulfill()
        }
        waitForExpectations(timeout: 2)

        let result = try XCTUnwrap(html)
        XCTAssertEqual(
            result,
            Self.testContentWithRemoteImageHavingPrefixScheme
        )
        XCTAssertTrue(result.contains(Self.remoteUrlWithPrefixText))

        // Check the html for the draft to save
        let e4 = expectation(description: "Get html for the draft")
        var draftHtml: String?
        getHtmlForDraft { result in
            draftHtml = result
            e4.fulfill()
        }
        waitForExpectations(timeout: 2)

        let draftResult = try XCTUnwrap(draftHtml)
        XCTAssertEqual(draftResult, Self.testContentForDraft)
        XCTAssertFalse(draftResult.contains(Self.remoteUrlWithPrefixText))
    }
 }

private extension HtmlEditorBehaviourTests {
    static let remoteUrlWithPrefixText = "proton-https://test.proton/test.png"
    static let testContentWithRemoteImage = """
 <html><head></head><body>  <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from Proton Mail for iOS</div></div> <div><br></div><div><br></div>On Wed, Dec 21, 2022 at 10:17 AM, XXX &lt;<a href=\"mailto:xxx@pm.me\" class=\"\">xxx@pm.me</a>&gt; wrote:</div><blockquote class=\"protonmail_quote\" type=\"cite\">  <div dir=\"ltr\"><img src=\"https://test.proton/test.png\" style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\"><img src=\"http://test2.proton/test.png\" style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\"><br clear=\"all\"><div><br></div>-- <br><div dir=\"ltr\" class=\"mail_signature\" data-smartmail=\"mail_signature\"><div dir=\"ltr\"><div dir=\"ltr\"><span style=\"font-size:small\"><font color=\"#6fa8dc\" face=\"microsoft jhenghei, sans-serif\">Best Regards</font></span><div><font face=\"microsoft jhenghei, sans-serif\" color=\"#3d85c6\" size=\"1\"><b></b></font></div></div></div></div></div>\n</blockquote></body></html>
"""
    static let testContentWithRemoteImageHavingPrefixScheme = """
   <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from Proton Mail for iOS</div></div> <div><br></div><div><br></div>On Wed, Dec 21, 2022 at 10:17 AM, XXX &lt;<a class=\"\" href=\"mailto:xxx@pm.me\">xxx@pm.me</a>&gt; wrote:<blockquote type=\"cite\" class=\"protonmail_quote\">  <div dir=\"ltr\"><img style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\" src=\"proton-https://test.proton/test.png\"><img style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\" src=\"proton-http://test2.proton/test.png\"><br clear=\"all\"><div><br></div>-- <br><div data-smartmail=\"mail_signature\" class=\"mail_signature\" dir=\"ltr\"><div dir=\"ltr\"><div dir=\"ltr\"><span style=\"font-size:small\"><font face=\"microsoft jhenghei, sans-serif\" color=\"#6fa8dc\">Best Regards</font></span><div><font size=\"1\" color=\"#3d85c6\" face=\"microsoft jhenghei, sans-serif\"><b></b></font></div></div></div></div></div>\n</blockquote>
"""
    static let testContentForDraft = """
   <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from Proton Mail for iOS</div></div> <div><br></div><div><br></div>On Wed, Dec 21, 2022 at 10:17 AM, XXX &lt;<a class=\"\" href=\"mailto:xxx@pm.me\">xxx@pm.me</a>&gt; wrote:<blockquote type=\"cite\" class=\"protonmail_quote\">  <div dir=\"ltr\"><img style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\" src=\"https://test.proton/test.png\"><img style=\"caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);\" src=\"http://test2.proton/test.png\"><br clear=\"all\"><div><br></div>-- <br><div data-smartmail=\"mail_signature\" class=\"mail_signature\" dir=\"ltr\"><div dir=\"ltr\"><div dir=\"ltr\"><span style=\"font-size:small\"><font face=\"microsoft jhenghei, sans-serif\" color=\"#6fa8dc\">Best Regards</font></span><div><font size=\"1\" color=\"#3d85c6\" face=\"microsoft jhenghei, sans-serif\"><b></b></font></div></div></div></div></div>\n</blockquote>
"""

    func getInnerHtmlOfEditor(completion: @escaping (String?) -> Void) {
        webView.evaluateJavaScript("html_editor.getRawHtml();") { result, error in
            if error != nil {
                XCTFail("JS command failed")
                completion(nil)
            } else {
                completion(result as? String)
            }
        }
    }

    func getHtmlForDraft(completion: @escaping (String?) -> Void) {
        webView.evaluateJavaScript("html_editor.getHtmlForDraft();") { result, error in
            if error != nil {
                XCTFail("JS command failed")
                completion(nil)
            } else {
                completion(result as? String)
            }
        }
    }
}
