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
import ProtonCore_TestingToolkit
import XCTest

final class DownloadServiceTests: XCTestCase {
    var sut: DownloadService!

    private var mockApiServer: APIServiceMock!
    private var mockFileManager: MockFileManager!
    private var mockApiServiceShouldReturnError: Bool!
    private var mockApiServiceResponseDelay: Double?

    private let resourceUrl1 = URL(string: "https://example.com/file1")!
    private let resourceUrl2 = URL(string: "https://example.com/file2")!
    private let destinationFile1 = URL(string: "file:///path/image1")!
    private let destinationFile2 = URL(string: "file:///path/image2")!

    override func setUp() {
        super.setUp()
        mockApiServer = makeMockApiService()
        mockFileManager = MockFileManager()
        mockApiServiceShouldReturnError = false

        let dependencies = DownloadService.Dependencies(fileManager: mockFileManager)
        sut = DownloadService(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiServer = nil
        mockFileManager = nil
    }

    func testDownload_whenNoDownloadsInProgress_returnsFile() {
        let expectation = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            XCTAssert(try! result.get() == destinationFile1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenDownloadAlreadyInProgress_onlyOneRequestIsMade() {
        let expectation1 = expectation(description: "")
        let expectation2 = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            XCTAssert(try! result.get() == destinationFile1)
            expectation1.fulfill()
        }
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            XCTAssert(try! result.get() == destinationFile1)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenDownloadAlreadyInProgressButRetryThresholdPassed_makesAnotherRequest() {
        let dependencies = DownloadService.Dependencies(fileManager: mockFileManager, retryThresholdInSeconds: 1.0)
        sut = DownloadService(dependencies: dependencies)
        mockApiServiceResponseDelay = dependencies.retryThresholdInSeconds + 0.5

        let expectation1 = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { result in
            XCTFail("this response is not expected after the download request is triggered again")
        }
        sleep(UInt32(dependencies.retryThresholdInSeconds))
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 2)
            XCTAssert(try! result.get() == destinationFile1)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenMultipleDownloads_sameNumberOfRequestsAreMade() {
        let expectation1 = expectation(description: "")
        let expectation2 = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 2)
            XCTAssert(try! result.get() == destinationFile1)
            expectation1.fulfill()
        }
        sut.download(url: resourceUrl2, to: destinationFile2, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 2)
            XCTAssert(try! result.get() == destinationFile2)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenDownloadFinishedAndRequestingTheSameUrl_makesANewRequest() {
        let expectation = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            XCTAssert(try! result.get() == destinationFile1)
            sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
                XCTAssert(mockApiServer.downloadStub.callCounter == 2)
                XCTAssert(try! result.get() == destinationFile1)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenFileAlreadyExists_returnsFileAndDoesNotMakeRequest() {
        mockFileManager.fileExistsResult = true

        let expectation = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 0)
            XCTAssert(try! result.get() == destinationFile1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDownload_whenDownloadFails_returnsError() {
        mockApiServiceShouldReturnError = true

        let expectation = expectation(description: "")
        sut.download(url: resourceUrl1, to: destinationFile1, apiService: mockApiServer) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            switch result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
}

extension DownloadServiceTests {

    private func makeMockApiService() -> APIServiceMock {
        let mockApiService = APIServiceMock()
        mockApiService.downloadStub.bodyIs { _, _, destinationURL, _, _, _, _, _, _, completion in
            let delay = self.mockApiServiceResponseDelay ?? [0.1, 0.25].randomElement()!
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                if self.mockApiServiceShouldReturnError {
                    completion(nil, nil, NSError(domain: "", code: -10))
                } else {
                    completion(nil, destinationURL, nil)
                }
            }
        }
        return mockApiService
    }
}
