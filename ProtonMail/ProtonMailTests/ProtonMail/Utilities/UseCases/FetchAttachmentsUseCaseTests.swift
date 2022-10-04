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
import XCTest
import ProtonCore_TestingToolkit

final class FetchAttachmentsTests: XCTestCase {
    var sut: FetchAttachments!
    private var mockApiServer: APIServiceMock!
    private var mockDownloadService: DownloadService!
    private var mockApiServiceShouldReturnError: Bool!
    private var sutDepencencies: FetchAttachments.Dependencies {
        FetchAttachments.Dependencies(apiService: mockApiServer, downloadService: mockDownloadService)
    }
    private let nsError = NSError(domain: "", code: -10)

    private let dummySingleAttachmentID = AttachmentID(rawValue: "id997")
    private var dummyAttachmentIDs: [AttachmentID] {
        ["id1", "id2", "id3"].map(AttachmentID.init(rawValue:))
    }

    override func setUp() {
        super.setUp()
        mockApiServer = makeMockApiService()
        mockDownloadService = DownloadService(dependencies: .init(fileManager: MockFileManager()))
        mockApiServiceShouldReturnError = false
        sut = FetchAttachments(dependencies: sutDepencencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiServer = nil
        mockDownloadService = nil
    }

    func testExecute_whenDownloadSucceeds_callbackIsCalledOncePerAttachment() {
        let expectation = expectation(description: "")
        var callbackCount = 0
        sut.execute(params: .init(attachments: dummyAttachmentIDs)) { [unowned self] result in
            DispatchQueue.main.async {
                callbackCount += 1
                XCTAssertNotNil(try? result.get())

                if callbackCount == self.dummyAttachmentIDs.count {
                    XCTAssert(self.mockApiServer.downloadStub.callCounter == self.dummyAttachmentIDs.count)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenDownloadFails_callbackIsCalledOncePerAttachment() {
        mockApiServiceShouldReturnError = true

        let expectation = expectation(description: "")
        var callbackCount = 0
        sut.execute(params: .init(attachments: dummyAttachmentIDs)) { [unowned self] result in
            DispatchQueue.main.async {
                callbackCount += 1
                switch result {
                case .success:
                    XCTFail()
                case .failure:
                    XCTAssert(true)
                }

                if callbackCount == self.dummyAttachmentIDs.count {
                    XCTAssert(self.mockApiServer.downloadStub.callCounter == self.dummyAttachmentIDs.count)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenDownloadFails_returnedErrorContainsAttachmentFile() {
        mockApiServiceShouldReturnError = true

        let expectation = expectation(description: "")
        sut.execute(params: .init(attachments: [dummySingleAttachmentID])) { [unowned self] result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                let customError = error as? FetchAttachmentError
                XCTAssertNotNil(customError)
                XCTAssert(customError?.attachmentFile.attachmentId == dummySingleAttachmentID)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenMultipleFetchAttachmentInstancesAreUsedForTheSameAttachment_OnlyOneRequestIsMade() {
        let sut1 = FetchAttachments(dependencies: sutDepencencies)
        let sut2 = FetchAttachments(dependencies: sutDepencencies)

        let expectation1 = expectation(description: "")
        let expectation2 = expectation(description: "")
        sut1.execute(params: .init(attachments: [dummySingleAttachmentID])) { result in
            XCTAssertNotNil((try? result.get()))
            expectation1.fulfill()
        }
        sut2.execute(params: .init(attachments: [dummySingleAttachmentID])) { result in
            XCTAssertNotNil((try? result.get()))
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 2.0)
        XCTAssert(mockApiServer.downloadStub.callCounter == 1)
    }

    func testExecute_returnsCorrectLocalFilePath() {
        let expectation = expectation(description: "")
        sut.execute(params: .init(attachments: [dummySingleAttachmentID])) { [unowned self] result in
            let returnedAttachmentFile = try! result.get()
            let expectedPath = "\(FileManager.default.attachmentDirectory)\(dummySingleAttachmentID)"
            XCTAssert(returnedAttachmentFile.attachmentId == dummySingleAttachmentID)
            XCTAssert(returnedAttachmentFile.fileUrl.absoluteString == expectedPath )
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
}

extension FetchAttachmentsTests {

    private func makeMockApiService() -> APIServiceMock {
        let mockApiService = APIServiceMock()
        mockApiService.downloadStub.bodyIs { _, requestUrl, destinationURL, _, _, _, _, _, _, completion in
            let dispatchTime: DispatchTime = .now() + [0.1, 0.25].randomElement()!
            DispatchQueue.global().asyncAfter(deadline: dispatchTime) {
                XCTAssert(requestUrl.contains("attachments"))
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
