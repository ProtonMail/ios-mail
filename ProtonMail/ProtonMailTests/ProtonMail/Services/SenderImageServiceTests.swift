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

import ProtonCore_TestingToolkit
import ProtonCore_UIFoundations
@testable import ProtonMail
import XCTest

final class SenderImageServiceTests: XCTestCase {
    var apiServiceMock: APIServiceMock!
    var sut: SenderImageService!
    var cacheUrl: URL!
    var imageTempUrl: URL!
    var internetStatusProviderMock: MockInternetConnectionStatusProviderProtocol!

    override func setUpWithError() throws {
        try super.setUpWithError()
        cacheUrl = FileManager.default.cachesDirectoryURL
            .appendingPathComponent("me.proton.senderImage", isDirectory: true)
        apiServiceMock = .init()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        internetStatusProviderMock = .init()
        internetStatusProviderMock.currentStatusStub.fixture = .connected
        sut = .init(dependencies: .init(apiService: apiServiceMock,
                                        internetStatusProvider: internetStatusProviderMock))

        // Prepare for api mock to write image data to disk
        imageTempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("senderImage", isDirectory: true)
        try FileManager.default.createDirectory(at: imageTempUrl, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        apiServiceMock = nil
        try FileManager.default.removeItem(at: cacheUrl)
        try FileManager.default.removeItem(at: imageTempUrl)
    }

    func testFetchSenderImage() throws {
        let imageData = UIImage(named: "mail_attachment_audio")?.pngData()
        apiServiceMock.downloadStub.bodyIs { _, _, fileUrl, _, _, _, _, _, _, completion in
            try? imageData?.write(to: fileUrl)
            let response = HTTPURLResponse(statusCode: 200)
            completion(response, nil, nil)
        }
        let e = expectation(description: "Closure is called")
        let e2 = expectation(description: "Closure is called")
        let e3 = expectation(description: "Closure is called")

        sut.fetchSenderImage(email: "test@pm.me", isDarkMode: false) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(imageData, data)
                e.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [e], timeout: 1)
 
        // Load the data from api at the first time.
        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)

        sut.fetchSenderImage(email: "test@pm.me", isDarkMode: false) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(imageData, data)
                e2.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [e2], timeout: 1)
        // The second fetch should not trigger the api.
        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)

        // Different parameter will trigger another api request.
        sut.fetchSenderImage(email: "test@pm.me", isDarkMode: true) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(imageData, data)
                e3.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [e3], timeout: 1)
        // The second fetch should not trigger the api.
        XCTAssertEqual(apiServiceMock.downloadStub.callCounter, 2)
    }

    func testFetchSenderImage_triggerMultipleTimesInAShortTimeForSameURL_onlyOneAPIReuest() throws {
        let imageData = UIImage(named: "mail_attachment_audio")?.pngData()
        apiServiceMock.downloadStub.bodyIs { _, _, fileUrl, _, _, _, _, _, _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                try? imageData?.write(to: fileUrl)
                let response = HTTPURLResponse(statusCode: 200)
                completion(response, nil, nil)
            }
        }

        var expectations: [XCTestExpectation] = []
        for _ in 0...4 {
            let e = expectation(description: "Closure is called")
            expectations.append(e)
            sut.fetchSenderImage(email: "test@pm.me", isDarkMode: false) { result in
                switch result {
                case .success(let data):
                    XCTAssertEqual(imageData, data)
                    e.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
        }

        wait(for: expectations, timeout: 2)

        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)
    }

    func testFetchSenderImage_lightModeSenderImageIsCached_turnOfflineAndSwitchToDarkMode_theLightModeImageIsReturned() {
        let imageData = UIImage(named: "mail_attachment_audio")?.pngData()
        apiServiceMock.downloadStub.bodyIs { _, _, fileUrl, _, _, _, _, _, _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                try? imageData?.write(to: fileUrl)
                let response = HTTPURLResponse(statusCode: 200)
                completion(response, nil, nil)
            }
        }

        // Cache the light mode image.
        let e = expectation(description: "Closure is called")
        sut.fetchSenderImage(email: "test@pm.me", isDarkMode: false) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(imageData, data)
                e.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [e], timeout: 1)

        // turn offline
        internetStatusProviderMock.currentStatusStub.fixture = .notConnected

        // check the image for dark mode.
        let e2 = expectation(description: "Closure is called")
        sut.fetchSenderImage(email: "test@pm.me", isDarkMode: true) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(imageData, data)
                e2.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [e2], timeout: 1)
    }
}
