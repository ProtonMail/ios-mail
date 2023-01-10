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

import Groot
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

final class MessageInfoProviderTest: XCTestCase {
    private var apiMock: APIServiceMock!
    private var delegateObject: ProviderDelegate!
    private var imageProxy: ImageProxyMock!
    private var message: MessageEntity!
    private var messageDecrypter: MessageDecrypterMock!
    private var sut: MessageInfoProvider!
    private var user: UserManager!
    private var mockFetchAttachment: MockFetchAttachment!

    override func setUpWithError() throws {
        try super.setUpWithError()

        Environment.locale = { .enUS }
        Environment.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let systemUpTime = SystemUpTimeMock(
            localServerTime: TimeInterval(1635745851),
            localSystemUpTime: TimeInterval(2000),
            systemUpTime: TimeInterval(2000)
        )
        let labelID = LabelID("0")
        apiMock = APIServiceMock()

        imageProxy = ImageProxyMock(apiService: apiMock)

        user = try Self.prepareUser(apiMock: apiMock)
        // testing are more thorough with this setting disabled, even though it is enabled by default
        user.userInfo.hideRemoteImages = 1

        message = try Self.prepareEncryptedMessage(
            plaintextBody: MessageDecrypterTestData.decryptedHTMLMimeBody(),
            mimeType: .multipartMixed,
            user: user
        )

        messageDecrypter = MessageDecrypterMock(userDataSource: user)
        mockFetchAttachment = MockFetchAttachment()

        sut = MessageInfoProvider(
            message: message,
            messageDecrypter: messageDecrypter,
            user: user,
            imageProxy: imageProxy,
            systemUpTime: systemUpTime,
            labelID: labelID,
            dependencies: .init(fetchAttachment: mockFetchAttachment)
        )
        delegateObject = ProviderDelegate()
        sut.set(delegate: delegateObject)
    }

    override func tearDownWithError() throws {
        sut = nil
        apiMock = nil
        delegateObject = nil
        imageProxy = nil
        message = nil
        messageDecrypter = nil
        user = nil

        try super.tearDownWithError()
    }

    func testBasicData() {
        XCTAssertEqual(sut.initials, "P")
        XCTAssertEqual(sut.senderEmail, "contact@protonmail.ch")
        XCTAssertEqual(sut.time, "May 02, 2018")
        XCTAssertEqual(sut.date, "May 2, 2018 at 4:43:19 PM")
        XCTAssertEqual(sut.originFolderTitle(isExpanded: false), "Inbox")
        XCTAssertEqual(sut.size, "2 KB")
        XCTAssertEqual(sut.simpleRecipient, "cc name, feng88@proton.me")

        let toList = sut.toData
        XCTAssertEqual(toList?.title, "To:")
        XCTAssertEqual(toList?.recipients.count, 1)
        XCTAssertEqual(toList?.recipients.first?.name, "feng88@proton.me")

        let ccList = sut.ccData
        XCTAssertEqual(ccList?.title, "Cc:")
        XCTAssertEqual(ccList?.recipients.count, 1)
        XCTAssertEqual(ccList?.recipients.first?.name, "cc name")
    }

    func testPGPChecker_keysAPIFailedAndNoAddressKeys_failsVerification() {
        let expectation1 = expectation(description: "get failed server validation error")
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion(nil, .success(["Code": 33101, "Error": "Server failed validation"]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(NSError.badResponse()))
            }
        }
        user.addresses.removeAll()

        delegateObject.senderContactUpdate.bodyIs { _, contact in
            expectation1.fulfill()
            let text = contact?.encryptionIconStatus?.text
            XCTAssertEqual(text, "Sender Verification Failed")
        }

        sut.initialize()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testMIMEDecrypt() throws {
        let expectation1 = expectation(description: "decrypt body test")
        expectation1.expectedFulfillmentCount = 3

        sut.initialize()

        delegateObject.contentUpdate.bodyIs { _, _ in
            expectation1.fulfill()
        }
        delegateObject.attachmentsUpdate.bodyIs { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(sut.inlineAttachments?.count, 0)
        XCTAssertEqual(sut.nonInlineAttachments.count, 3)
        XCTAssertEqual(sut.mimeAttachments.count, 2)
        XCTAssertNotNil(sut.contents)
    }

    func testMessageDecrypter_whenMessageBodyChanges_isCalled() async throws {
        XCTAssertEqual(messageDecrypter.decryptCallCount, 0)

        sut.initialize()
        waitForMessageToBePrepared()
        XCTAssertEqual(messageDecrypter.decryptCallCount, 1)

        simulateMessageUpdateWithSameBodyAsBefore()
        waitForMessageToBePrepared()
        XCTAssertEqual(messageDecrypter.decryptCallCount, 1)

        try simulateMessageUpdateWithBodyDifferentThanBefore()
        waitForMessageToBePrepared()
        XCTAssertEqual(messageDecrypter.decryptCallCount, 2)
    }

    func testMessageDecrypter_whenSettingAreChanged_isNotCalled() async throws {
        sut.initialize()
        waitForMessageToBePrepared()
        XCTAssertEqual(messageDecrypter.decryptCallCount, 1)

        XCTAssertNotEqual(sut.remoteContentPolicy, .allowed)
        sut.remoteContentPolicy = .allowed
        waitForMessageToBePrepared()

        XCTAssertNotEqual(sut.embeddedContentPolicy, .allowed)
        sut.embeddedContentPolicy = .allowed
        waitForMessageToBePrepared()

        XCTAssertNotEqual(sut.displayMode, .expanded)
        sut.displayMode = .expanded
        waitForMessageToBePrepared()

        XCTAssertEqual(messageDecrypter.decryptCallCount, 1)
    }

    func testImageProxy_ifDisabled_whenRemoteContentIsAllowed_isNotCalled() async throws {
        user.userInfo.imageProxy = .none
        sut.remoteContentPolicy = .allowed
        waitForMessageToBePrepared()
        XCTAssertEqual(imageProxy.processCallCount, 0)
    }

    func testImageProxy_ifEnabled_whenRemoteContentIsAllowed_isCalled() async throws {
        enableImageProxyAndRemoteContent()
        XCTAssertEqual(imageProxy.processCallCount, 1)
    }

    func testImageProxy_whenMessageBodyChanges_isCalled() async throws {
        enableImageProxyAndRemoteContent()

        simulateMessageUpdateWithSameBodyAsBefore()
        waitForMessageToBePrepared()
        XCTAssertEqual(imageProxy.processCallCount, 1)

        try simulateMessageUpdateWithBodyDifferentThanBefore()
        waitForMessageToBePrepared()
        XCTAssertEqual(imageProxy.processCallCount, 2)
    }

    func testImageProxy_whenSettingsOtherThanRemoteContentAreChanged_isNotCalled() async throws {
        enableImageProxyAndRemoteContent()

        XCTAssertNotEqual(sut.embeddedContentPolicy, .allowed)
        sut.embeddedContentPolicy = .allowed
        waitForMessageToBePrepared()

        XCTAssertNotEqual(sut.displayMode, .expanded)
        sut.displayMode = .expanded
        waitForMessageToBePrepared()

        XCTAssertEqual(messageDecrypter.decryptCallCount, 1)
    }

    func testTrackerProtectionSummary_whenProxyIsUsed_isSetAndDelegateIsNotified() async throws {
        XCTAssertNil(sut.trackerProtectionSummary)
        XCTAssertEqual(delegateObject.trackerProtectionSummaryChangedStub.callCounter, 0)

        enableImageProxyAndRemoteContent()

        XCTAssertNotNil(sut.trackerProtectionSummary)
        XCTAssertEqual(delegateObject.trackerProtectionSummaryChangedStub.callCounter, 1)
    }

    // this test has unfortunately been broken by https://gitlab.protontech.ch/ProtonMail/protonmail-ios/-/merge_requests/2307
    // not sure how to fix it in a clean way
//    func testTrackerProtectionSummary_whenMessageBodyChanges_isBrieflyNil() async throws {
//        enableImageProxyAndRemoteContent()
//
//        try simulateMessageUpdateWithBodyDifferentThanBefore()
//        XCTAssertNil(sut.trackerProtectionSummary)
//        XCTAssertEqual(delegateObject.trackerProtectionSummaryChangedStub.callCounter, 2)
//
//        waitForMessageToBePrepared()
//        XCTAssertNotNil(sut.trackerProtectionSummary)
//        XCTAssertEqual(delegateObject.trackerProtectionSummaryChangedStub.callCounter, 3)
//    }

    func testIfAnImageProxyRequestFails_promptsUserToReplaceFailedRequestMarkersWithOriginalURLs() async throws {
        imageProxy.stubbedFailedRequests = [
            [
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
            ]: UnsafeRemoteURL(value: "https://example.com/image")
        ]
        let stubbedInitialBody = "<img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img>"
        let expectedProcessedBody = "<img src=\"https://example.com/image\"></img>"

        message = try Self.prepareEncryptedMessage(plaintextBody: stubbedInitialBody, mimeType: .textHTML, user: user)
        sut.update(message: message)
        enableImageProxyAndRemoteContent()

        XCTAssert(sut.shouldShowImageProxyFailedBanner)

        sut.reloadImagesWithoutProtection()
        waitForMessageToBePrepared()

        XCTAssertFalse(sut.shouldShowImageProxyFailedBanner)
        XCTAssertEqual(sut.bodyParts?.originalBody, expectedProcessedBody)
    }

    func testStoresDryRunResults() throws {
        let summary = TrackerProtectionSummary(trackers: ["tracker": [UnsafeRemoteURL(value: "https://example.com")]])
        let dryRunOutput = ImageProxyDryRunOutput(summary: summary)
        sut.imageProxy(imageProxy, didFinishDryRunWithOutput: dryRunOutput)

        XCTAssertEqual(sut.trackerProtectionSummary, dryRunOutput.summary)
    }

    func testDryRunResultsDoNotOverwriteRealRunResults() {
        let realOutput = ImageProxyOutput(
            failedUnsafeRemoteURLs: [:],
            safeBase64Contents: [:],
            summary: TrackerProtectionSummary(trackers: ["tracker": [UnsafeRemoteURL(value: "https://example.com")]])
        )
        sut.imageProxy(imageProxy, didFinishWithOutput: realOutput)

        let dryRunOutput = ImageProxyDryRunOutput(summary: TrackerProtectionSummary(trackers: [:]))
        sut.imageProxy(imageProxy, didFinishDryRunWithOutput: dryRunOutput)

        XCTAssertEqual(sut.trackerProtectionSummary, realOutput.summary)
    }
}

extension MessageInfoProviderTest {
    private static func prepareUser(apiMock: APIServiceMock) throws -> UserManager {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: "1", privateKey: keyPair.privateKey)
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "",
            domainID: nil,
            email: "",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )

        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userAddresses = [address]
        user.userInfo.userKeys = [key]
        user.authCredential.mailboxpassword = keyPair.passphrase
        return user
    }

    private static func prepareEncryptedMessage(
        plaintextBody: String,
        mimeType: Message.MimeType,
        user: UserManager
    ) throws -> MessageEntity {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.addressKeys.toArmoredPrivateKeys[0],
            cleartext: plaintextBody
        ).value

        let parsedObject = testMessageDetailData.parseObjectAny()!
        let testContext = MockCoreDataStore.testPersistentContainer.newBackgroundContext()

        return try testContext.performAndWait {
             let messageObject = try XCTUnwrap(
                GRTJSONSerialization.object(
                    withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: testContext
                ) as? Message
            )
            messageObject.userID = "userID"
            messageObject.isDetailDownloaded = true
            messageObject.body = encryptedBody
            messageObject.mimeType = mimeType.rawValue
            return MessageEntity(messageObject)
        }
    }

    /// This method is needed because most of the related code runs on a background queue
    private func waitForMessageToBePrepared() {
        Thread.sleep(forTimeInterval: 0.1)
    }

    private func simulateMessageUpdateWithSameBodyAsBefore() {
        let identicalMessage: MessageEntity = message
        sut.update(message: identicalMessage)
    }

    private func simulateMessageUpdateWithBodyDifferentThanBefore() throws {
        let differentMessage = try Self.prepareEncryptedMessage(
            plaintextBody: String.randomString(500),
            mimeType: .textPlain,
            user: user
        )
        sut.update(message: differentMessage)
    }

    private func enableImageProxyAndRemoteContent() {
        user.userInfo.imageProxy = .imageProxy
        sut.remoteContentPolicy = .allowed
        waitForMessageToBePrepared()
    }
}

final private class ProviderDelegate: MessageInfoProviderDelegate {

    @FuncStub(update(senderContact:)) var senderContactUpdate
    func update(senderContact: ContactVO?) {
        senderContactUpdate(senderContact)
    }

    func hideDecryptionErrorBanner() {

    }

    func showDecryptionErrorBanner() {

    }

    func updateBannerStatus() {

    }

    @FuncStub(update(content:)) var contentUpdate
    func update(content: WebContents?) {
        contentUpdate(content)
    }

    func update(hasStrippedVersion: Bool) {

    }

    func update(renderStyle: MessageRenderStyle) {

    }

    func sendDarkModeMetric(isApply: Bool) {

    }

    @FuncStub(updateAttachments) var attachmentsUpdate
    func updateAttachments() {
        attachmentsUpdate()
    }

    @FuncStub(trackerProtectionSummaryChanged) var trackerProtectionSummaryChangedStub
    func trackerProtectionSummaryChanged() {
        trackerProtectionSummaryChangedStub()
    }
}

private class ImageProxyMock: ProtonMail.ImageProxy {
    var stubbedFailedRequests: [Set<UUID>: UnsafeRemoteURL] = [:]
    private(set) var processCallCount = 0

    init(apiService: APIServiceMock) {
        let dependencies = Dependencies(apiService: apiService)
        super.init(dependencies: dependencies)
    }

    override func process(body: String, delegate: ImageProxyDelegate) throws -> String {
        processCallCount += 1
        let trackerProtectionSummary = TrackerProtectionSummary(trackers: [:])
        let output = ImageProxyOutput(
            failedUnsafeRemoteURLs: stubbedFailedRequests,
            safeBase64Contents: [:],
            summary: trackerProtectionSummary
        )
        delegate.imageProxy(self, didFinishWithOutput: output)
        return body
    }
}
