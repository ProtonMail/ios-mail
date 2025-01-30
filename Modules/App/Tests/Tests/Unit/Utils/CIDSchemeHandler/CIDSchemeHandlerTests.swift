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

@testable import InboxCore
@testable import ProtonMail
import InboxTesting
import Nimble
import proton_app_uniffi
import XCTest
import WebKit

/**
 The `CIDSchemeHandler` is part of `InboxCore`, but its tests (`CIDSchemeHandlerTests`) are located in
 the App module because moving them to `InboxCore` would create a circular dependency.

 Specifically, `CIDSchemeHandlerTests` depends on `InboxTesting`, and `InboxTesting` itself relies on classes
 from `InboxCore`. To avoid this circular dependency, the tests remain in the App module.
 */
class CIDSchemeHandlerTests: BaseTestCase {

    var sut: CIDSchemeHandler!
    var embeddedImageProviderSpy: EmbeddedImageProviderSpy!
    private var urlSchemeTaskSpy: WKURLSchemeTaskSpy!

    var stubbedMessageID: ID {
        .init(value: 7)
    }

    override func setUp() {
        super.setUp()

        embeddedImageProviderSpy = .init()
        sut = CIDSchemeHandler(embeddedImageProvider: embeddedImageProviderSpy)
    }

    override func tearDown() {
        sut = nil
        embeddedImageProviderSpy = nil

        super.tearDown()
    }

    func testFetchingEmbeddedImage_WhenCIDIsMissing_ItReturnsError() {
        let request = URLRequest(url: .init(string: "https://proton.me").unsafelyUnwrapped)
        urlSchemeTaskSpy = .init(request: request)
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        XCTAssertEqual(embeddedImageProviderSpy.invokedEmbeddedImageWithCID, [])
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeFailWithError.count, 1)
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeFailWithError.compactMap(\.asHandlerError), [.missingCID])
    }

    func testFetchingEmbeddedImage_WhenImageIsMissing_ItReturnsError() {
        let cidValue = "abcdef"
        embeddedImageProviderSpy.stubbedResult = .error(.unexpected(.unknown))
        urlSchemeTaskSpy = .init(request: .init(url: .cid(cidValue)))
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        expect(self.embeddedImageProviderSpy.invokedEmbeddedImageWithCID).toEventually(equal([cidValue]))
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeFailWithError.count, 1)
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeFailWithError.compactMap(\.asProtonError), [.unexpected(.unknown)])
    }

    func testFetchingEmbeddedImage_WhenImageIsLoaded_ItReturnsImage() {
        let cidValue = "abcdef"
        let url = URL.cid(cidValue)
        let image = EmbeddedAttachmentInfo.testData
        urlSchemeTaskSpy = .init(request: .init(url: url))
        embeddedImageProviderSpy.stubbedResult = .ok(image)
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        expect(self.embeddedImageProviderSpy.invokedEmbeddedImageWithCID).toEventually(equal([cidValue]))
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.url), [url])
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.mimeType), ["image/png"])
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.expectedContentLength), [Int64(image.data.count)])
    }

    func testWebViewStopURLSchemeTask_ItDoesNotDoAnything() {
        urlSchemeTaskSpy = .init(request: .init(url: .cid("abc")))
        sut.webView(WKWebView(), stop: urlSchemeTaskSpy)

        XCTAssertEqual(urlSchemeTaskSpy.didFinishInvokeCount, 0)
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeDidReceiveResponse, [])
        XCTAssertEqual(urlSchemeTaskSpy.didInvokeDidReceivedData, [])
        XCTAssertTrue(urlSchemeTaskSpy.didInvokeFailWithError.isEmpty)
    }

}

private class WKURLSchemeTaskSpy: NSObject, WKURLSchemeTask {

    private(set) var didInvokeDidReceiveResponse: [URLResponse] = []
    private(set) var didInvokeDidReceivedData: [Data] = []
    private(set) var didInvokeFailWithError: [Error] = []
    private(set) var didFinishInvokeCount = 0

    init(request: URLRequest) {
        self.request = request
    }

    // MARK: - WKURLSchemeTask

    var request: URLRequest

    func didReceive(_ response: URLResponse) {
        didInvokeDidReceiveResponse.append(response)
    }

    func didReceive(_ data: Data) {
        didInvokeDidReceivedData.append(data)
    }

    func didFinish() {
        didFinishInvokeCount += 1
    }

    func didFailWithError(_ error: Error) {
        didInvokeFailWithError.append(error)
    }

}

private extension URL {

    static func cid(_ value: String) -> URL {
        .init(string: "cid:\(value)").unsafelyUnwrapped
    }

}

private extension Error {

    var asProtonError: ProtonError? {
        self as? ProtonError
    }

    var asHandlerError: CIDSchemeHandler.HandlerError? {
        self as? CIDSchemeHandler.HandlerError
    }

}

private extension EmbeddedAttachmentInfo {

    static var testData: Self {
        .init(
            data: UIImage(resource: .protonLogo).pngData().unsafelyUnwrapped,
            mime: "image/png",
            height: nil,
            width: nil
        )
    }

}
