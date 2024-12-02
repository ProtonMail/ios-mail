// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import WebKit
import XCTest

final class HTTPRequestSecureLoaderTests: XCTestCase {
    private var container: UIViewController!
    private var webView: WKWebView!
    private var navigationDelegateMock: MockNavigationDelegate!
    private var apiMock: APIServiceMock!
    private var sut: HTTPRequestSecureLoader!

    override func setUp() {
        super.setUp()
        navigationDelegateMock = .init()
        container = .init()
        apiMock = .init()

        apiMock.dohInterfaceStub.fixture = DohMock()

        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.phoneNumber, .link]
        config.defaultWebpagePreferences.allowsContentJavaScript = false

        sut = .init(schemeHandler: .init(userKeys: .init(
            privateKeys: [],
            addressesPrivateKeys: [],
            mailboxPassphrase: .init(value: "")
        ), imageProxy: .init(dependencies: .init(apiService: apiMock, imageCache: MockImageProxyCacheProtocol()))))
        sut.inject(into: config)

        webView = PMWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = navigationDelegateMock
        container.view.addSubview(webView)
        webView.fillSuperview()
        container.loadViewIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        webView = nil
        container = nil
        sut = nil
        apiMock = nil
        navigationDelegateMock = nil
    }

    func testLoad_callTwiceInAShortTime_shouldNotGetFailProvisionalNavigation() {
        let content = WebContents(
            body: bodyWithoutRemoteImages,
            remoteContentMode: .allowedThroughProxy,
            messageDisplayMode: .collapsed
        )
        navigationDelegateMock.didFailProvisionalNavigationIsCalled = {
            XCTFail("didFailProvisionalNavigation should not be called")
        }
        let e = expectation(description: "Closure is called")
        sut.observeHeight { _ in
            e.fulfill()
        }
        webView.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
        _ = sut.load(contents: content, in: webView)
        // Call second time in a short time
        let e2 = expectation(description: "Closure is called")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
            _ = self.sut.load(contents: content, in: self.webView)
            e2.fulfill()
        }
        wait(for: [e2], timeout: 0.5)

        // Expect the `didFinish` is called
        waitForExpectations(timeout: 1)
    }

    func testLoad_callTwiceInTheSameTime_shouldLoadSuccessfully() {
        let content = WebContents(
            body: bodyWithoutRemoteImages,
            remoteContentMode: .allowedThroughProxy,
            messageDisplayMode: .collapsed
        )
        navigationDelegateMock.didFailProvisionalNavigationIsCalled = {
            XCTFail("didFailProvisionalNavigation should not be called")
        }
        let e = expectation(description: "Closure is called")
        sut.observeHeight { _ in
            e.fulfill()
        }

        webView.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
        _ = sut.load(contents: content, in: webView)
        _ = sut.load(contents: content, in: webView)

        // Expect the `didFinish` is called
        waitForExpectations(timeout: 1)
    }
}
