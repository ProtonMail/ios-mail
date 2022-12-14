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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

final class FetchAttachmentTests: XCTestCase {
    var sut: FetchAttachment!

    private static var bundle: Bundle {
        Bundle(for: FetchAttachmentTests.self)
    }
    private static func url(for resource: String, ext: String? = nil) -> URL {
        bundle.url(forResource: resource, withExtension: ext)!
    }
    private let dummyAttachmentsFolder = FetchAttachmentTests.url(for: "dataPacket").deletingLastPathComponent()
    private let dummySingleAttachmentID = AttachmentID(rawValue: "dataPacket")
    private var mockApiServer: APIServiceMock!
    private var mockDownloadService: DownloadService!
    private var mockApiServiceShouldReturnError: Bool!
    private var sutDepencencies: FetchAttachment.Dependencies {
        FetchAttachment.Dependencies(
            apiService: mockApiServer,
            downloadService: mockDownloadService,
            attachmentCacheFolder: dummyAttachmentsFolder
        )
    }
    private let nsError = NSError(domain: "", code: -10)

    override func setUp() {
        super.setUp()
        mockApiServer = makeMockApiService()
        mockDownloadService = DownloadService(dependencies: .init(fileManager: MockFileManager()))
        mockApiServiceShouldReturnError = false
        sut = FetchAttachment(dependencies: sutDepencencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiServer = nil
        mockDownloadService = nil
    }

    func testExecute_whenSucceedsAndPurposeIsAttachment_resultIsCorrect() {
        let expectation = expectation(description: "")
        let params = makeDummyParams(.decryptAndEncodeAttachment)

        sut.execute(params: params) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            let attachmentFile = try! result.get()
            let expectedPath = "\(dummyAttachmentsFolder)\(params.attachmentID)"

            XCTAssert(attachmentFile.attachmentId == params.attachmentID)
            XCTAssert(attachmentFile.fileUrl.absoluteString == expectedPath)
            XCTAssert(attachmentFile.encoded == DummyCrypto.plainData.encodeBase64())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenSucceedsAndPurposeIsPublicKey_resultIsCorrect() {
        let expectation = expectation(description: "")
        let params = makeDummyParams(.decryptAndEncodePublicKey)

        sut.execute(params: params) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            let attachmentFile = try! result.get()
            let expectedPath = "\(dummyAttachmentsFolder)\(params.attachmentID)"

            XCTAssert(attachmentFile.attachmentId == params.attachmentID)
            XCTAssert(attachmentFile.fileUrl.absoluteString == expectedPath)
            XCTAssert(attachmentFile.encoded == DummyCrypto.plainData)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenSucceedsAndPurposeIsDownloadOnly_resultIsCorrect() {
        let expectation = expectation(description: "")
        let params = makeDummyParams(.onlyDownload)

        sut.execute(params: params) { [unowned self] result in
            XCTAssert(mockApiServer.downloadStub.callCounter == 1)
            let attachmentFile = try! result.get()
            let expectedPath = "\(dummyAttachmentsFolder)\(params.attachmentID)"

            XCTAssert(attachmentFile.attachmentId == params.attachmentID)
            XCTAssert(attachmentFile.fileUrl.absoluteString == expectedPath)
            XCTAssertTrue(attachmentFile.encoded.isEmpty)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenDownloadFails_returnedErrorContainsAttachmentID() {
        mockApiServiceShouldReturnError = true
        let params = makeDummyParams(.decryptAndEncodeAttachment)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                let customError = error as? FetchAttachmentError
                XCTAssertNotNil(customError)
                XCTAssert(customError?.attachmentID == dummySingleAttachmentID)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenDecryptionFails_returnedErrorContainsAttachmentDecrypterError() {
        let params = makeDummyParams(.decryptAndEncodeAttachment, setNilKeyPacket: true)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                let customError = error as? FetchAttachmentError
                XCTAssertNotNil(customError)
                XCTAssert(customError?.attachmentID == dummySingleAttachmentID)
                let errorThrown = customError?.error as? AttachmentDecrypterError
                XCTAssertNotNil(errorThrown == .failDecodingKeyPacket)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenMultipleFetchAttachmentInstancesAreUsedForTheSameAttachment_OnlyOneRequestIsMade() {
        let sut1 = FetchAttachment(dependencies: sutDepencencies)
        let sut2 = FetchAttachment(dependencies: sutDepencencies)

        let expectation1 = expectation(description: "")
        let expectation2 = expectation(description: "")
        let params = makeDummyParams(.decryptAndEncodeAttachment)

        sut1.execute(params: params) { result in
            XCTAssertNotNil((try? result.get()))
            expectation1.fulfill()
        }
        sut2.execute(params: params) { result in
            XCTAssertNotNil((try? result.get()))
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 2.0)
        XCTAssert(mockApiServer.downloadStub.callCounter == 1)
    }
}

extension FetchAttachmentTests {
    private enum DummyCrypto {
        static let encryptedData = try! Data(contentsOf: FetchAttachmentTests.url(for: "dataPacket"))
        static let keyPacket = try! Data(contentsOf: FetchAttachmentTests.url(for: "keyPacket"))
        static let mailboxPassphrase = try! Passphrase(
            value: String(contentsOf: FetchAttachmentTests.url(for: "passphrase", ext: "txt"))
        )
        static let plainData = try! String(contentsOf: FetchAttachmentTests.url(for: "plainData", ext: "txt"))
        static let userPrivateKey: ArmoredKey = {
            let data = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self)
                .url(forResource: "userKey", withExtension: nil)!)
            let unArmoredKey = UnArmoredKey(value: data)
            return try! unArmoredKey.armor()
        }()

        static var userAddressKey: Key {
            let token = try! String(contentsOf: FetchAttachmentTests.url(for: "case1_token", ext: "txt"))
            let signature = try! String(contentsOf: FetchAttachmentTests.url(for: "case1_signature", ext: "txt"))
            let addressKey = try! String(contentsOf: FetchAttachmentTests.url(for: "case1_addressKey", ext: "txt"))
            return Key(keyID: "dummyKeyId", privateKey: addressKey, token: token, signature: signature)
        }

        static var userKeys: UserKeys {
            UserKeys(
                privateKeys: [userPrivateKey],
                addressesPrivateKeys: [userAddressKey],
                mailboxPassphrase: mailboxPassphrase
            )
        }
    }
}

extension FetchAttachmentTests {

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

    private func makeDummyParams(
        _ purpose: FetchAttachment.Params.Purpose,
        setNilKeyPacket: Bool = false
    ) -> FetchAttachment.Params {
        FetchAttachment.Params(
            attachmentID: dummySingleAttachmentID,
            attachmentKeyPacket: setNilKeyPacket
            ? nil
            : DummyCrypto.keyPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)),
            purpose: purpose,
            userKeys: DummyCrypto.userKeys
        )
    }
}
