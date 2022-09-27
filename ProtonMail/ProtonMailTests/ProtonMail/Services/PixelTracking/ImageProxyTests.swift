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

import ProtonCore_Services
import ProtonCore_TestingToolkit
import SwiftSoup
import XCTest

@testable import ProtonMail

class ImageProxyTests: XCTestCase {
    private var apiServiceMock: APIServiceMock!
    private var sut: ImageProxy!

    private var trackingImageURL: String {
        "https://tracking.example.com/images/track.open"
    }

    private let nonTrackingMessage = """
<html>
    <body>
        Hey, check out this image.
        <img src="https://example.com/images/tiger.png" width="48" height="48" alt="">
    </body>
</html>
"""

    private var trackingMessage: String {
"""
<html>
    <body>
        Hey, I like tracking.
        <img src="\(trackingImageURL)" width="1" height="1" alt="">
    </body>
</html>
"""
    }

    private let base64Image = """
iVBORw0KGgoAAAANSUhEUgAAANQAAAArCAAAAAAlcfkIAAAAHGlET1QAAAACAAAAAAAAABYAAAAoAAAAFgAAABUAAAGS+6h5QAAAAV5JREFUaN7szz9IAmEYBvAnsVArUDziIocKglqCoGhIoyxri6B/NDQUjY4NtQSRRGODLZrYEATtEQgtBdGfpUDKghaTuKEho6nEp+HO87yw/eJ7p5f3ex74fuA/HAiUQAmUQAmUQAmUQAmUQAmUdVDP3X2vfx8sgLpZXNb3bPCgsAvEKrK/DhZArcH5Udq30F5URgZzFVntkMaKdVBPQLK0d2KzauXESigGENS2a9iyVSsxS6GSsL2oWxhjpAK8kfyKD8j1XbPH+mHdjConSCb6G+XQXhhR8mwiriUiC4+mNyoAM/PN7sCRljE+lmff73F1LKVJFhOTrZ6h1Xdq5fvpJvfoBZmZk72hy6qozwZsq7+UcFgyfI8DvjY7erWDH+oU9JohwfwUYHcDQJTcQI+aKPiQMr1RAe4kOGzADs1FffIzAJzAKZkbBmpqgZaUWr71wgU4rh4kOIG6cyPqBwAA//+fMws4AAADZklEQVTtlW9o1HUcx993bu62eeqYbNOGXdDQukHYAy0rRyxSEamG1AQFawMrCkZJK1oRSP8ehHlI9iBsSjEy0JHaA/tLMsfUE6GgP5BN17xD1ubG3O3Pea8e/H6/u+/v9+uE60EP4j6PPvd5v9+f+77u+H1/wqg2RQHo1eIUJKUR+Ex152Hu+FF7sCWyQAsjkUg6mzIc7FDV4SmG36jUPhgu0YC9ryHj0UhK1Su+So+1qGrcG8zWdi068BeJD25As+p7x6e/jyp8yQo3nsr8fodW10dO3rh0l5pMDpkf+qTzAC16FgeqS22ObA1o1y4zZDrOBIJxAB7SPmCLngJgo/b4tKTUkABGQvrBJ9rVHwgO2G23wlcAJu/UJkhKK68CX0hVvwLfqCSdD4oV6gBG5+tcluGQKg/O3RTKcDynJzDO9q0qxoA/guWjPi0p/QxAo7p9ol3PqNVpN+tVqzmh4CRJ6ReAhHQCYEIazAv1rmrTsF+NOYbZ1VJt58WbQBmOB7XXdbaVigGvqM2v2cvgfn3oD1rVpJjT3qbjVjNTqoFseFL608KwIP8R6so8fQn3ao/BkOpaIgWfT+WFMhzLdcR1tr2Kwmyt4vg0N5Q3aFV2SjqoeBavpzAoNmsrv6n0KubXTvesk1rzQ+Uca/W+62zXKnSKw7oHfJobyhu06j5nChF9bjWZkM4WCHVU5ROvqQUXFBCTLjuDp/UC/opJl2m3o9mztWsbzTpktS35oXxB+zZ+JPdrP2k1cQWvFwg1W6MDER0zoDLW31+iM86qt/W4K2M4jijQBzAVtZ+GuMpOB5akAK/mhvIFATgm9dntpwr2A2Q26FEKhOJFLVXdnAG1a+uFWVJvKjTtrPpaoX5GerMRw0Gzwt3jM9+tknZa4hotVafVujU3lDf4Vl0HwMMKfzLB8DuDsF6VH42mf9yo8FDBUD9Jesm4waeqpdL6Mqk7t6pZWqj5o3bCdDB4txQo0/IeaRsAB6XgRcvo1jxQnmCNlACG1krzKqTdkFgvBULSLScpGIo1zvvDTiY7H1hW3tA6YKy63nH7glWvX8u+k3MOmNm9LrxsxxD7b+2ybsZqbXKMLs0D5QnG6qxHKP3ehppF0Z0XAD5+LLK46eUx/gXU/6GKUEWoIlQRqghVhCpC/cf1N496FtdBQ0ZOAAAAAElFTkSuQmCC
"""

    private let testImageContentType = "image/png"

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiServiceMock = APIServiceMock()
        let dependencies = ImageProxy.Dependencies(apiService: apiServiceMock)
        sut = ImageProxy(dependencies: dependencies)

        apiServiceMock.dohStub.fixture = DohMock()

        apiServiceMock.downloadStub.bodyIs { _, urlString, destinationDirectoryURL, _, _, _, _, _, _, completion in
            let url = URL(string: urlString)!

            var headers: [String: String] = [
                "Content-Type": self.testImageContentType
            ]

            let originalSrcURL = url.query!.components(separatedBy: "=")[1]
            if originalSrcURL == self.trackingImageURL {
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

    override func tearDownWithError() throws {
        sut = nil
        apiServiceMock = nil

        try super.tearDownWithError()
    }

    func testDownloadsImagesAndReplacesURLsWithBlobsInMessageBody() async throws {
        let expectedProcessedBody = """
<html>
    <body>
        Hey, check out this image.
        <img src="data:\(testImageContentType);base64,\(base64Image)" width="48" height="48" alt="">
    </body>
</html>
"""

        let output = try sut.process(body: nonTrackingMessage)
        assertHTMLsAreEqual(output.processedBody, expectedProcessedBody)
    }

    func testDoesntClearSrcAttributeIfProxyRequestFails() async throws {
        let expectedProcessedBody = """
<html>
    <body>
        Hey, check out this image.
        <img src="https://example.com/images/tiger.png" width="48" height="48" alt="">
    </body>
</html>
"""
        apiServiceMock.downloadStub.bodyIs { _, urlString, _, _, _, _, _, _, _, completion in
            let url = URL(string: urlString)!
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: [:])
            completion(response, nil, nil)
        }

        let output = try sut.process(body: nonTrackingMessage)
        assertHTMLsAreEqual(output.processedBody, expectedProcessedBody)
    }

    func testDetectsTrackers() async throws {
        let nonTrackingOutput = try sut.process(body: nonTrackingMessage)
        XCTAssert(nonTrackingOutput.summary.trackers.isEmpty)

        let trackingOutput = try sut.process(body: trackingMessage)
        XCTAssertEqual(trackingOutput.summary.trackers.count, 1)
    }

    func testOnlyWorksOnRemoteImages() async throws {
        let incomingBody = """
<html>
    <body background=>
        Hey, check out this image.
        <img src="cid:0f4f5a6fe4a42704bac4@news.proton.me">
    </body>
</html>
"""
        let output = try sut.process(body: incomingBody)
        assertHTMLsAreEqual(output.processedBody, incomingBody)
        XCTAssert(output.summary.trackers.isEmpty)
    }

    func testDoesntClearSrcAttributeInCaseOfNonImageResponses() async throws {
        let expectedProcessedBody = """
<html>
    <body>
        Hey, check out this image.
        <img src="https://example.com/images/tiger.png" width="48" height="48" alt="">
    </body>
</html>
"""
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

        let output = try sut.process(body: nonTrackingMessage)
        assertHTMLsAreEqual(output.processedBody, expectedProcessedBody)
    }

    // This particular way of asserting is needed, because SwiftSoup does some minor stylistic changes, like adding
    // missing <head> etc.
    private func assertHTMLsAreEqual(_ first: String, _ second: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let firstDocument = try SwiftSoup.parse(first)
            let secondDocument = try SwiftSoup.parse(second)

            // pretty print needs to be disabled so that minor whitespace differences don't matter
            for document in [firstDocument, secondDocument] {
                document.outputSettings().prettyPrint(pretty: false)
            }

            // for some reason, a simple == check on two Nodes does not work - it's as if it was an identity check
            XCTAssertEqual("\(firstDocument)", "\(secondDocument)", file: file, line: line)
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
    }
}
