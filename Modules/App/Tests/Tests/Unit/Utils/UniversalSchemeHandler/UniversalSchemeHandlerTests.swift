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

import InboxTesting
import Testing
import WebKit
import proton_app_uniffi

@testable import InboxCore
@testable import ProtonMail

@MainActor
final class UniversalSchemeHandlerTests {
    private let sut: UniversalSchemeHandler
    private let imageProxySpy = ImageProxySpy()
    private var urlSchemeTaskSpy: WKURLSchemeTaskSpy!
    private var proxyImageFailCallCount = 0

    init() {
        sut = .init(imageProxy: imageProxySpy, imagePolicy: .safe)

        sut.onProxyImageLoadFail = { [unowned self] in
            proxyImageFailCallCount += 1
        }
    }

    @Test
    func testFetchingEmbeddedImage_WhenImageIsMissing_ItReturnsError() async throws {
        let cidValue = "abcdef"
        let stubbedError = AttachmentDataError.other(.unexpected(.unknown))

        imageProxySpy.stubbedResult = .error(stubbedError)
        urlSchemeTaskSpy = .init(request: .init(url: .cid(cidValue)))
        self.sut.webView(WKWebView(), start: urlSchemeTaskSpy!)

        try await expectToEventually(self.urlSchemeTaskSpy.didInvokeFailWithError.count == 1)
        #expect(urlSchemeTaskSpy.didInvokeFailWithError.compactMap(\.asAttachmentDataError) == [stubbedError])
    }

    @Test
    func testFetchingEmbeddedImage_WhenProxyFailsLoadingImage_ItCallsImageProxyError() async throws {
        let cidValue = "abcdef"
        imageProxySpy.stubbedResult = .error(.proxyFailed)
        urlSchemeTaskSpy = .init(request: .init(url: .cid(cidValue)))
        self.sut.webView(WKWebView(), start: urlSchemeTaskSpy!)

        try await expectToEventually(self.proxyImageFailCallCount == 1)
        #expect(urlSchemeTaskSpy.didInvokeFailWithError.count == 0)
    }

    @Test
    func testFetchingEmbeddedImage_WhenImageIsLoaded_ItReturnsImage() async throws {
        let cidValue = "abcdef"
        let url = URL.cid(cidValue)
        let image = AttachmentData.testData
        urlSchemeTaskSpy = .init(request: .init(url: url))
        imageProxySpy.stubbedResult = .ok(image)
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        try await expectToEventually(self.urlSchemeTaskSpy.didFinishInvokeCount == 1)
        #expect(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.url) == [url])
        #expect(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.mimeType) == ["image/png"])
        #expect(urlSchemeTaskSpy.didInvokeDidReceiveResponse.map(\.expectedContentLength) == [Int64(image.data.count)])
    }

    @Test
    func testFetchingEmbeddedImage_WhenStopIsCalled_ItDoesNotDoAnything() {
        let cidValue = "abcdef"
        let url = URL.cid(cidValue)
        let image = AttachmentData.testData
        urlSchemeTaskSpy = .init(request: .init(url: url))
        imageProxySpy.stubbedResult = .ok(image)
        let webView = WKWebView()
        sut.webView(webView, start: urlSchemeTaskSpy)

        sut.webView(webView, stop: urlSchemeTaskSpy)

        #expect(urlSchemeTaskSpy.didFinishInvokeCount == 0)
        #expect(urlSchemeTaskSpy.didInvokeDidReceiveResponse == [])
        #expect(urlSchemeTaskSpy.didInvokeDidReceivedData == [])
        #expect(urlSchemeTaskSpy.didInvokeFailWithError.count == 0)
    }

    @Test
    func testWebViewStopURLSchemeTask_ItDoesNotDoAnything() {
        urlSchemeTaskSpy = .init(request: .init(url: .cid("abc")))
        sut.webView(WKWebView(), stop: urlSchemeTaskSpy)

        #expect(urlSchemeTaskSpy.didFinishInvokeCount == 0)
        #expect(urlSchemeTaskSpy.didInvokeDidReceiveResponse == [])
        #expect(urlSchemeTaskSpy.didInvokeDidReceivedData == [])
        #expect(urlSchemeTaskSpy.didInvokeFailWithError.count == 0)
    }

    @Test
    func testFetchingEmbeddedImage_ItCallsLoadImageWithSafePolicy() async throws {
        let cidValue = "abcdef"
        let image = AttachmentData.testData
        imageProxySpy.stubbedResult = .ok(image)
        urlSchemeTaskSpy = .init(request: .init(url: .cid(cidValue)))
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        try await expectToEventually(!self.imageProxySpy.invokedLoadImageWithURLs.isEmpty)
        #expect(imageProxySpy.invokedLoadImageWithURLs.first?.policy == .safe)
    }

    @Test
    func testFetchingEmbeddedImage_WhenPolicyUpdatedToUnsafe_ItCallsLoadImageWithUnsafePolicy() async throws {
        let cidValue = "abcdef"
        let image = AttachmentData.testData
        imageProxySpy.stubbedResult = .ok(image)
        urlSchemeTaskSpy = .init(request: .init(url: .cid(cidValue)))

        sut.updateImagePolicy(with: .unsafe)
        sut.webView(WKWebView(), start: urlSchemeTaskSpy)

        try await expectToEventually(!self.imageProxySpy.invokedLoadImageWithURLs.isEmpty)
        #expect(imageProxySpy.invokedLoadImageWithURLs.first?.policy == .unsafe)
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
    var asAttachmentDataError: AttachmentDataError? {
        self as? AttachmentDataError
    }
}

private extension AttachmentData {
    static var testData: Self {
        .init(
            data: UIImage(resource: .protonLogo).pngData().unsafelyUnwrapped,
            mime: "image/png"
        )
    }
}
