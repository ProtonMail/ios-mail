// Copyright (c) 2022 Proton AG
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

import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

class ImageProxyTests: XCTestCase {
    private var apiServiceMock: APIServiceMock!
    private var delegate: MockImageProxyDelegate!
    private var sut: ImageProxy!

    private let incomingMessage = """
<html>
    <head>
        <style>
            /* Sometimes message CSS contains URLs like https://example.com that should not be fetched. */

            @import url("https://tracking.example.com/font.ttf");

            @font-face {
                font-family: myFont;
                src: url("https://tracking.example.com/font.woff");
            }

            body {
                background-image : url ( " https://tracking.example.com/images/1.png ");
            }

            div {
                background: url(http://tracking.example.com/images/2.png);
            }
        </style>
    </head>
    <body background =" https://tracking.example.com/images/3.png">
        Hey, I like tracking.
        <a href="https://tracking.example.com" />
            <img src="//tracking.example.com/images/4.png"  style="background: url('https://tracking.example.com/images/5.png')">
        </a>
        <div style='background-image : url("https://tracking.example.com/images/6.png")' />
        <svg>
            <image href="http://tracking.example.com/images/7.png" />
            <image xlink:href="http://tracking.example.com/images/8.png" />
        </svg>
        <img src="https://example.com/images/safe.png">
        <img src="cid:123">
        <img src="data:image/png;base64,">
    </body>
</html>
"""

    private let expectedStrippedMessage = """
<html>
    <head>
        <style>/* Sometimes message CSS contains URLs like https://example.com that should not be fetched. */

            @import url("160C6ADB-F096-4AF8-A400-6EEB816FB4DD");

            @font-face {
                font-family: myFont;
                src: url("CF9E127D-B000-417A-8731-50F7D7895BDA");
            }

            body {
                background-image : url ( " E621E1F8-C36C-495A-93FC-0C247A3E6E5F ");
            }

            div {
                background: url(AA2A26E9-B322-4BB3-ACFC-CBA6C24E6E07);
            }</style>
    </head>
    <body background =" BB3C52FC-ED32-4300-A33C-4D71DE9A4B93">
        Hey, I like tracking.
        <a href="https://tracking.example.com" />
            <img src="55C88C7A-ADDE-4BC3-81FA-85F69E6FA64E"  style="background: url('6CDD72F8-63F0-45C5-B3CF-0D932B21061F')">
        </a>
        <div style='background-image : url(&quot;8CE737FF-EEB2-4D5F-8A7C-B093C785864D&quot;)' />
        <svg>
            <image href="CC96C0C5-4B5B-432E-8A95-B32AC55BB343" />
            <image xlink:href="D7FCCD3B-B0E9-4BA2-ACC9-A76AEC705E96" />
        </svg>
        <img src="9954E711-8EAA-4B88-83E2-84FB42AED355">
        <img src="cid:123">
        <img src="data:image/png;base64,">
    </body>
</html>
"""

    private let base64Image = """
iVBORw0KGgoAAAANSUhEUgAAANQAAAArCAAAAAAlcfkIAAAAHGlET1QAAAACAAAAAAAAABYAAAAoAAAAFgAAABUAAAGS+6h5QAAAAV5JREFUaN7szz9IAmEYBvAnsVArUDziIocKglqCoGhIoyxri6B/NDQUjY4NtQSRRGODLZrYEATtEQgtBdGfpUDKghaTuKEho6nEp+HO87yw/eJ7p5f3ex74fuA/HAiUQAmUQAmUQAmUQAmUQAmUdVDP3X2vfx8sgLpZXNb3bPCgsAvEKrK/DhZArcH5Udq30F5URgZzFVntkMaKdVBPQLK0d2KzauXESigGENS2a9iyVSsxS6GSsL2oWxhjpAK8kfyKD8j1XbPH+mHdjConSCb6G+XQXhhR8mwiriUiC4+mNyoAM/PN7sCRljE+lmff73F1LKVJFhOTrZ6h1Xdq5fvpJvfoBZmZk72hy6qozwZsq7+UcFgyfI8DvjY7erWDH+oU9JohwfwUYHcDQJTcQI+aKPiQMr1RAe4kOGzADs1FffIzAJzAKZkbBmpqgZaUWr71wgU4rh4kOIG6cyPqBwAA//+fMws4AAADZklEQVTtlW9o1HUcx993bu62eeqYbNOGXdDQukHYAy0rRyxSEamG1AQFawMrCkZJK1oRSP8ehHlI9iBsSjEy0JHaA/tLMsfUE6GgP5BN17xD1ubG3O3Pea8e/H6/u+/v9+uE60EP4j6PPvd5v9+f+77u+H1/wqg2RQHo1eIUJKUR+Ex152Hu+FF7sCWyQAsjkUg6mzIc7FDV4SmG36jUPhgu0YC9ryHj0UhK1Su+So+1qGrcG8zWdi068BeJD25As+p7x6e/jyp8yQo3nsr8fodW10dO3rh0l5pMDpkf+qTzAC16FgeqS22ObA1o1y4zZDrOBIJxAB7SPmCLngJgo/b4tKTUkABGQvrBJ9rVHwgO2G23wlcAJu/UJkhKK68CX0hVvwLfqCSdD4oV6gBG5+tcluGQKg/O3RTKcDynJzDO9q0qxoA/guWjPi0p/QxAo7p9ol3PqNVpN+tVqzmh4CRJ6ReAhHQCYEIazAv1rmrTsF+NOYbZ1VJt58WbQBmOB7XXdbaVigGvqM2v2cvgfn3oD1rVpJjT3qbjVjNTqoFseFL608KwIP8R6so8fQn3ao/BkOpaIgWfT+WFMhzLdcR1tr2Kwmyt4vg0N5Q3aFV2SjqoeBavpzAoNmsrv6n0KubXTvesk1rzQ+Uca/W+62zXKnSKw7oHfJobyhu06j5nChF9bjWZkM4WCHVU5ROvqQUXFBCTLjuDp/UC/opJl2m3o9mztWsbzTpktS35oXxB+zZ+JPdrP2k1cQWvFwg1W6MDER0zoDLW31+iM86qt/W4K2M4jijQBzAVtZ+GuMpOB5akAK/mhvIFATgm9dntpwr2A2Q26FEKhOJFLVXdnAG1a+uFWVJvKjTtrPpaoX5GerMRw0Gzwt3jM9+tknZa4hotVafVujU3lDf4Vl0HwMMKfzLB8DuDsF6VH42mf9yo8FDBUD9Jesm4waeqpdL6Mqk7t6pZWqj5o3bCdDB4txQo0/IeaRsAB6XgRcvo1jxQnmCNlACG1krzKqTdkFgvBULSLScpGIo1zvvDTiY7H1hW3tA6YKy63nH7glWvX8u+k3MOmNm9LrxsxxD7b+2ybsZqbXKMLs0D5QnG6qxHKP3ehppF0Z0XAD5+LLK46eUx/gXU/6GKUEWoIlQRqghVhCpC/cf1N496FtdBQ0ZOAAAAAElFTkSuQmCC
"""

    // this is needed in order to for the UUIDs in the stripped message to be deterministic, but still varied
    private let predefinedUUIDs: [UnsafeRemoteURL: UUID] = [
        "https://tracking.example.com/images/1.png": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
        "http://tracking.example.com/images/2.png": "AA2A26E9-B322-4BB3-ACFC-CBA6C24E6E07",
        "https://tracking.example.com/images/3.png": "BB3C52FC-ED32-4300-A33C-4D71DE9A4B93",
        "//tracking.example.com/images/4.png": "55C88C7A-ADDE-4BC3-81FA-85F69E6FA64E",
        "https://tracking.example.com/images/5.png": "6CDD72F8-63F0-45C5-B3CF-0D932B21061F",
        "https://tracking.example.com/images/6.png": "8CE737FF-EEB2-4D5F-8A7C-B093C785864D",
        "http://tracking.example.com/images/7.png": "CC96C0C5-4B5B-432E-8A95-B32AC55BB343",
        "http://tracking.example.com/images/8.png": "D7FCCD3B-B0E9-4BA2-ACC9-A76AEC705E96",
        "https://example.com/images/safe.png": "9954E711-8EAA-4B88-83E2-84FB42AED355",
        "https://tracking.example.com/font.ttf": "160C6ADB-F096-4AF8-A400-6EEB816FB4DD",
        "https://tracking.example.com/font.woff": "CF9E127D-B000-417A-8731-50F7D7895BDA"
    ].reduce(into: [:]) { acc, element in
        acc[UnsafeRemoteURL(value: element.key)] = UUID(uuidString: element.value)!
    }

    private let testImageContentType = "image/png"

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiServiceMock = APIServiceMock()
        delegate = MockImageProxyDelegate()
        sut = ImageProxy(dependencies: .init(apiService: apiServiceMock, imageCache: MockImageProxyCacheProtocol()))

        apiServiceMock.dohInterfaceStub.fixture = DohMock()

        apiServiceMock.downloadStub.bodyIs { _, urlString, destinationDirectoryURL, _, _, _, _, _, _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                let url = URL(string: urlString)!

                var headers: [String: String] = [
                    "Content-Type": self.testImageContentType
                ]

                let originalSrcURL = url.query!.components(separatedBy: "=")[1].removingPercentEncoding!
                if originalSrcURL.contains(check: "track") {
                    headers["x-pm-tracker-provider"] = "{0:\"MailChimp.com\"}"
                }

                try! FileManager.default.createDirectory(
                    at: destinationDirectoryURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                try! Data(base64Encoded: self.base64Image)!.write(to: destinationDirectoryURL)

                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)
                completion(response, destinationDirectoryURL, nil)
            }
        }

        apiServiceMock.requestJSONStub.bodyIs { _, _, urlString, _, _, _, _, _, _, _, _, _, completion in
            let url = URL(string: urlString)!

            var headers: [String: String] = [:]

            let originalSrcURL = url.query!.components(separatedBy: "=")[1].removingPercentEncoding!
            if originalSrcURL.contains(check: "track") {
                headers["x-pm-tracker-provider"] = "{0:\"MailChimp.com\"}"
            }

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
            let task = URLSessionDataTaskMock(response: response)
            completion(task, .success([:]))
        }

        sut.predefinedUUIDForURL = { [unowned self] url in
            self.predefinedUUIDs[url]!
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        apiServiceMock = nil
        delegate = nil

        try super.tearDownWithError()
    }

    func testFetchRemoteImageIfNeeded() {
        let url = URL(string: "proton-http://test.com")!
        let e = expectation(description: "Closure is called")

        sut.fetchRemoteImageIfNeeded(url: url) { result in
            switch result {
            case .success(_):
                break
            case .failure(_):
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFetchRemoteImageIfNeeded_callMultipleTimesForSameURL_apiIsCalledOnce() {
        let url = URL(string: "proton-http://test.com")!
        var expectations: [XCTestExpectation] = []

        for _ in 0...5 {
            let e = expectation(description: "Closure is called")
            sut.fetchRemoteImageIfNeeded(url: url) { result in
                switch result {
                case .success(_):
                    break
                case .failure(_):
                    XCTFail("Should not reach here")
                }
                e.fulfill()
            }
            expectations.append(e)
        }

        wait(for: expectations, timeout: 2)

        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)
    }

    func testFetchRemoteImageIfNeeded_withUrlWithoutScheme_errorIsReturned() {
        let url = URL(string: "test.com")!
        let e = expectation(description: "Closure is called")

        sut.fetchRemoteImageIfNeeded(url: url) { result in
            switch result {
            case .success(_):
                XCTFail("Should not reach here")
            case .failure(let error):
                if let err = error as? ImageProxyError {
                    XCTAssertEqual(err, .schemeNotFound)
                } else {
                    XCTFail("Should not reach here")
                }
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFetchRemoteImageIfNeeded_withSchemeHasNoProtonPrefix_errorIsReturned() {
        let url = URL(string: "https://test.com")!
        let e = expectation(description: "Closure is called")

        sut.fetchRemoteImageIfNeeded(url: url) { result in
            switch result {
            case .success(_):
                XCTFail("Should not reach here")
            case .failure(let error):
                if let err = error as? ImageProxyError {
                    XCTAssertEqual(err, .schemeHasNoPrefix)
                } else {
                    XCTFail("Should not reach here")
                }
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFetchRemoteImageIfNeeded_withAPIError_errorIsReturned() {
        apiServiceMock.downloadStub.bodyIs { _, urlString, destinationDirectoryURL, _, _, _, _, _, _, completion in
            let url = URL(string: urlString)!

            try! FileManager.default.createDirectory(
                at: destinationDirectoryURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let headers: [String: String] = [
                "Content-Type": "application/json"
            ]
            let errorResponse: [String: String] = [
                "Error": "something went wrong"
            ]

            try! JSONSerialization.data(withJSONObject: errorResponse).write(to: destinationDirectoryURL)

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)
            completion(response, destinationDirectoryURL, nil)
        }
        let url = URL(string: "proton-http://test.com")!
        let e = expectation(description: "Closure is called")

        sut.fetchRemoteImageIfNeeded(url: url) { result in
            switch result {
            case .success(_):
                XCTFail("Should not reach here")
            case .failure(_):
                break
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
	}

    private func assertRemoteURLsHaveBeenListedForReload(
        _ failedRequests: [Set<UUID>: UnsafeRemoteURL],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectedFailedRequests: [Set<UUID>: UnsafeRemoteURL] = predefinedUUIDs
            .filter { $0.key.value.hasSuffix(".png") }
            .reduce(into: [:]) { acc, element in
                acc[[element.value]] = element.key
            }
        XCTAssertEqual(failedRequests, expectedFailedRequests, file: file, line: line)
    }
}
