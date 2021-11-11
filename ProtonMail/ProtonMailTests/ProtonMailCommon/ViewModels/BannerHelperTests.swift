// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class BannerHelperTests: XCTestCase {

    var bodyWithImages: String!
    var bodyWithoutImages: String!
    var sut: BannerHelper!

    override func setUp() {
        super.setUp()
        bodyWithImages = bodyWithRemoteImages
        bodyWithoutImages = bodyWithoutRemoteImages
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCalculateEmbeddedBannerStatus_notHavingEmbeddedImages_withAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: 0,
                           isHavingEmbeddedImages: false)
        XCTAssertFalse(sut.shouldShowEmbeddedBanner())
    }

    func testCalculateEmbeddedBannerStatus_havingEmbeddedImages_withAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: 0,
                           isHavingEmbeddedImages: true)
        XCTAssertFalse(sut.shouldShowEmbeddedBanner())
    }

    func testCalculateEmbeddedBannerStatus_notHavingEmbeddedImages_withNotAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .disallowed,
                           remoteContentPolicy: 0,
                           isHavingEmbeddedImages: false)
        XCTAssertFalse(sut.shouldShowEmbeddedBanner())
    }

    func testCalculateEmbeddedBannerStatus_havingEmbeddedImages_withNotAllowPolicy_returnTrue() {
        sut = BannerHelper(embeddedContentPolicy: .disallowed,
                           remoteContentPolicy: 0,
                           isHavingEmbeddedImages: true)
        XCTAssertTrue(sut.shouldShowEmbeddedBanner())
    }

    func testCalculateRemoteBannerStatus_havingImages_withAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: WebContents.RemoteContentPolicy.allowed.rawValue,
                           isHavingEmbeddedImages: false)
        let expectation = expectation(description: "getRemoteBannerStatus")
        sut.calculateRemoteBannerStatus(bodyToCheck: bodyWithRemoteImages) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testCalculateRemoteBannerStatus_havingImages_withNotAllowPolicy_returnTrue() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: WebContents.RemoteContentPolicy.disallowed.rawValue,
                           isHavingEmbeddedImages: false)
        let expectation = expectation(description: "getRemoteBannerStatus")
        sut.calculateRemoteBannerStatus(bodyToCheck: bodyWithRemoteImages) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testCalculateRemoteBannerStatus_notHavingImages_withAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: WebContents.RemoteContentPolicy.allowed.rawValue,
                           isHavingEmbeddedImages: false)
        let expectation = expectation(description: "getRemoteBannerStatus")
        sut.calculateRemoteBannerStatus(bodyToCheck: bodyWithoutImages) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testCalculateRemoteBannerStatus_notHavingImages_withNotAllowPolicy_returnFalse() {
        sut = BannerHelper(embeddedContentPolicy: .allowed,
                           remoteContentPolicy: WebContents.RemoteContentPolicy.disallowed.rawValue,
                           isHavingEmbeddedImages: false)
        let expectation = expectation(description: "getRemoteBannerStatus")
        sut.calculateRemoteBannerStatus(bodyToCheck: bodyWithoutImages) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}
