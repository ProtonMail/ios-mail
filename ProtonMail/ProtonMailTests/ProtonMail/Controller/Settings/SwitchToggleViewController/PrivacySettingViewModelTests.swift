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

import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest
@testable import ProtonMail

final class PrivacySettingViewModelTests: XCTestCase {
    var sut: PrivacySettingViewModel!
    var user: UserManager!
    var apiMock: APIServiceMock!
    var metadataStrippingProvider: AttachmentMetadataStrippingMock!

    var expected: [PrivacySettingViewModel.SettingPrivacyItem] {
        var items: [PrivacySettingViewModel.SettingPrivacyItem] = [
            .autoLoadRemoteContent,
            .autoLoadEmbeddedImage,
            .blockEmailTracking,
            .linkOpeningMode,
            .metadataStripping
        ]

        if !UserInfo.isImageProxyAvailable {
            items.removeAll { $0 == .blockEmailTracking }
        }

        return items
    }

    let errorTemplate = APIServiceMock.APIError(domain: "test.com", code: -999)

    override func setUpWithError() throws {
        self.apiMock = APIServiceMock()
        self.user = UserManager(api: apiMock, role: .member)
        self.metadataStrippingProvider = AttachmentMetadataStrippingMock()
        self.sut = PrivacySettingViewModel(user: user, metaStrippingProvider: metadataStrippingProvider)
    }

    override func tearDownWithError() throws {
        sut = nil
        user = nil
        apiMock = nil
        metadataStrippingProvider = nil
    }

    func testConstant() throws {
        XCTAssertEqual(sut.title, LocalString._privacy)
        XCTAssertEqual(sut.sectionNumber, 1)
        XCTAssertEqual(sut.rowNumber, expected.count)
        XCTAssertEqual(sut.headerTopPadding, 8)
        XCTAssertEqual(sut.footerTopPadding, 0)
        for i in 0...5 {
            XCTAssertNil(sut.sectionHeader(of: i))
            XCTAssertNil(sut.sectionFooter(of: i))
        }

        for i in 0...3 {
            let item = sut.privacySections[i]
            XCTAssertEqual(item, expected[i])
        }
    }

    func testPrivacyItemStatus_metadataStrip() throws {
        metadataStrippingProvider.metadataStripping = .stripMetadata
        try testPrivacyItem(.metadataStripping, expectedResult: true)

        metadataStrippingProvider.metadataStripping = .sendAsIs
        try testPrivacyItem(.metadataStripping, expectedResult: false)
    }

    func testPrivacyItemStatus_showImages() throws {
        user.userInfo.hideRemoteImages = 1
        user.userInfo.hideEmbeddedImages = 1
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: false)
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: false)

        user.userInfo.hideRemoteImages = 0
        user.userInfo.hideEmbeddedImages = 1
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: true)
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: false)

        user.userInfo.hideRemoteImages = 1
        user.userInfo.hideEmbeddedImages = 0
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: false)
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: true)

        user.userInfo.hideRemoteImages = 0
        user.userInfo.hideEmbeddedImages = 0
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: true)
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: true)
    }

    func testPrivacyItemStatus_linkConfirmation() throws {
        user.userInfo.linkConfirmation = .confirmationAlert
        try testPrivacyItem(.linkOpeningMode, expectedResult: true)

        user.userInfo.linkConfirmation = .openAtWill
        try testPrivacyItem(.linkOpeningMode, expectedResult: false)
    }

    func testToggle_metadataStrip() throws {
        let expectation1 = expectation(description: "Get callback")
        let index = try XCTUnwrap(expected.firstIndex(of: .metadataStripping))
        let indexPath = IndexPath(row: index, section: 0)

        metadataStrippingProvider.metadataStripping = .sendAsIs
        sut.toggle(for: indexPath, to: true) { [self] error in
            XCTAssertNil(error)
            XCTAssertEqual(metadataStrippingProvider.metadataStripping, .stripMetadata)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)

        let expectation2 = expectation(description: "Get callback")
        metadataStrippingProvider.metadataStripping = .stripMetadata
        sut.toggle(for: indexPath, to: false) { [self] error in
            XCTAssertNil(error)
            XCTAssertEqual(metadataStrippingProvider.metadataStripping, .sendAsIs)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1)
    }

    func testToggle_remoteContent_enable() throws {
        let path = "/mail/v4/settings/hide-remote-images"
        let params = ["HideRemoteImages": 0]
        // succeed
        user.userInfo.hideRemoteImages = 1
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: false)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .autoLoadRemoteContent, isSuccess: true, targetStatus: true, expectedResult: true)

        // failure
        user.userInfo.hideRemoteImages = 1
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: false)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .autoLoadRemoteContent, isSuccess: false, targetStatus: true, expectedResult: false)
    }

    func testToggle_remoteContent_disable() throws {
        let path = "/mail/v4/settings/hide-remote-images"
        let params = ["HideRemoteImages": 1]
        // succeed
        user.userInfo.hideRemoteImages = 0
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: true)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .autoLoadRemoteContent, isSuccess: true, targetStatus: false, expectedResult: false)

        // failure
        user.userInfo.hideRemoteImages = 0
        try testPrivacyItem(.autoLoadRemoteContent, expectedResult: true)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .autoLoadRemoteContent, isSuccess: false, targetStatus: false, expectedResult: true)
    }

    func testToggle_embedded_enable() throws {
        let path = "/mail/v4/settings/hide-embedded-images"
        let params = ["HideEmbeddedImages": 0]
        // succeed
        user.userInfo.hideEmbeddedImages = 1
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: false)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .autoLoadEmbeddedImage, isSuccess: true, targetStatus: true, expectedResult: true)

        // failure
        user.userInfo.hideEmbeddedImages = 1
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: false)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .autoLoadEmbeddedImage, isSuccess: false, targetStatus: true, expectedResult: false)
    }

    func testToggle_embedded_disable() throws {
        let path = "/mail/v4/settings/hide-embedded-images"
        let params = ["HideEmbeddedImages": 1]
        // succeed
        user.userInfo.hideEmbeddedImages = 0
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: true)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .autoLoadEmbeddedImage, isSuccess: true, targetStatus: false, expectedResult: false)

        // failure
        user.userInfo.hideEmbeddedImages = 0
        try testPrivacyItem(.autoLoadEmbeddedImage, expectedResult: true)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .autoLoadEmbeddedImage, isSuccess: false, targetStatus: false, expectedResult: true)
    }

    func testToggle_linkConfirmation_enable() throws {
        let path = "/mail/v4/settings/confirmlink"
        let params = ["ConfirmLink": 1]

        // succeed
        user.userInfo.linkConfirmation = .openAtWill
        try testPrivacyItem(.linkOpeningMode, expectedResult: false)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .linkOpeningMode, isSuccess: true, targetStatus: true, expectedResult: true)

        // failure
        user.userInfo.linkConfirmation = .openAtWill
        try testPrivacyItem(.linkOpeningMode, expectedResult: false)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .linkOpeningMode, isSuccess: false, targetStatus: true, expectedResult: false)
    }

    func testToggle_linkConfirmation_disable() throws {
        let path = "/mail/v4/settings/confirmlink"
        let params = ["ConfirmLink": 0]

        // succeed
        user.userInfo.linkConfirmation = .confirmationAlert
        try testPrivacyItem(.linkOpeningMode, expectedResult: true)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .linkOpeningMode, isSuccess: true, targetStatus: false, expectedResult: false)

        // failure
        user.userInfo.linkConfirmation = .confirmationAlert
        try testPrivacyItem(.linkOpeningMode, expectedResult: true)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .linkOpeningMode, isSuccess: false, targetStatus: false, expectedResult: true)
    }

    func testToggle_block_email_tracker_enable() throws {
        let path = "/mail/v4/settings/imageproxy"
        let params = ["Action": 1,
                      "ImageProxy": 2]
        // succeed
        user.userInfo.imageProxy = ImageProxy(rawValue: 0)
        try testPrivacyItem(.blockEmailTracking, expectedResult: false)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .blockEmailTracking, isSuccess: true, targetStatus: true, expectedResult: true)

        // failure
        user.userInfo.imageProxy = ImageProxy(rawValue: 0)
        try testPrivacyItem(.blockEmailTracking, expectedResult: false)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .blockEmailTracking, isSuccess: false, targetStatus: true, expectedResult: false)
    }

    func testToggle_block_email_tracker_disable() throws {
        let path = "/mail/v4/settings/imageproxy"
        let params = ["Action": 0,
                      "ImageProxy": 2]
        // succeed
        user.userInfo.imageProxy = ImageProxy(rawValue: 2)
        try testPrivacyItem(.blockEmailTracking, expectedResult: true)

        requestStub(path: path, params: params, error: nil)
        try testToggle(item: .blockEmailTracking, isSuccess: true, targetStatus: false, expectedResult: false)

        // failure
        user.userInfo.imageProxy = ImageProxy(rawValue: 2)
        try testPrivacyItem(.blockEmailTracking, expectedResult: true)

        requestStub(path: path, params: params, error: errorTemplate)
        try testToggle(item: .blockEmailTracking, isSuccess: false, targetStatus: false, expectedResult: true)
    }
}

extension PrivacySettingViewModelTests {
    private func testPrivacyItem(_ item: PrivacySettingViewModel.SettingPrivacyItem,
                                 expectedResult: Bool,
                                 file: StaticString = #file,
                                 line: UInt = #line) throws {
        let index = try XCTUnwrap(expected.firstIndex(of: item), file: file, line: line)
        let indexPath = IndexPath(row: index, section: 0)
        let result = try XCTUnwrap(sut.cellData(for: indexPath), file: file, line: line)
        XCTAssertEqual(result.title, expected[index].description, file: file, line: line)
        XCTAssertEqual(result.status, expectedResult, file: file, line: line)
    }

    private func requestStub(path: String, params: [String : Int], error: APIServiceMock.APIError?) {
        apiMock.requestJSONStub.bodyIs { _, _, reqPath, reqParam, _, _, _, _, _, _, completion in
            guard reqPath == path else {
                XCTFail("URL path is wrong")
                return
            }
            XCTAssertEqual(reqParam as! [String : Int], params)
            if let error = error {
                completion(nil, .failure(error))
            } else {
                completion(nil, .success([:]))
            }
        }
    }

    private func testToggle(item: PrivacySettingViewModel.SettingPrivacyItem,
                            isSuccess: Bool,
                            targetStatus: Bool,
                            expectedResult: Bool,
                            file: StaticString = #file,
                            line: UInt = #line) throws {
        let expectation1 = expectation(description: "Closure is called")
        let index = try XCTUnwrap(expected.firstIndex(of: item), file: file, line: line)
        let indexPath = IndexPath(row: index, section: 0)
        sut.toggle(for: indexPath, to: targetStatus) { error in
            if isSuccess {
                XCTAssertNil(error, file: file, line: line)
            } else {
                XCTAssertEqual(error?.code, self.errorTemplate.code, file: file, line: line)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2)
        try testPrivacyItem(item, expectedResult: expectedResult, file: file, line: line)
    }
}
