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

@testable import ProtonMail
import SwiftUI
import XCTest

final class SenderImageLoaderTests: XCTestCase {
    private var sut: SenderImageLoader!
    private var mockCache: MemoryCache<String, UIImage>!
    private var mockImageDataSource: MockImageDataSource!
    private var mockDependencies: SenderImageLoader.Dependencies {
        .init(imageDataSource: mockImageDataSource, cache: mockCache)
    }
    private let cachedImage = UIImage()

    override func setUp() {
        super.setUp()
        mockCache = .init()
        mockImageDataSource = MockImageDataSource()
    }

    // MARK: Init

    func testInit_withThereIsNoCachedImage_itShouldSetSenderImageAsEmpty() {
        let address = "test_address"
        sut = SenderImageLoader(address: address, dependencies: mockDependencies)

        switch sut.senderImage {
        case .empty:
            XCTAssert(true)
        case .image:
            XCTFail("Loader should not load an image if none exists in the cache.")
        }
    }

    func testInit_whenThereIsCachedImage_itShouldSetSenderImageWithCachedImage() {
        let address = "test_address"
        mockDependencies.cache.setObject(cachedImage, for: address)
        sut = SenderImageLoader(address: address, dependencies: mockDependencies)

        switch sut.senderImage {
        case .image(let image):
            XCTAssertEqual(image, cachedImage, "Loader should load the image from the cache.")
        case .empty:
            XCTFail("Loader should not be empty when there is a cached image.")
        }
    }

    // MARK: loadImage

    func testLoadImage_whenDataSourceReturnsNil_itShouldSetSenderImageAsEmpty() async {
        let params = SenderImageDataParameters()
        mockImageDataSource.imageToReturn = nil

        sut = SenderImageLoader(address: "test_address", dependencies: mockDependencies)
        await sut.loadImage(for: params, colorScheme: .light)

        switch sut.senderImage {
        case .empty:
            XCTAssert(true)
        case .image:
            XCTFail("Loader should not set an image if none is returned.")
        }
    }

    func testLoadImage_whenDataSourceReturnsImage_itShouldSetSenderImageWithReturnedImage() async {
        let params = SenderImageDataParameters()
        let expectedImage = UIImage()
        mockImageDataSource.imageToReturn = expectedImage

        sut = SenderImageLoader(address: "test_address", dependencies: mockDependencies)
        await sut.loadImage(for: params, colorScheme: .light)

        switch sut.senderImage {
        case .image(let image):
            XCTAssertEqual(image, expectedImage, "Loader should set the image received from the data source.")
        case .empty:
            XCTFail("Loader should not be empty when a valid image is returned.")
        }
    }
}

private final class MockImageDataSource: SenderImageDataSource {
    var imageToReturn: UIImage?

    func senderImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async -> UIImage? {
        return imageToReturn
    }
}
