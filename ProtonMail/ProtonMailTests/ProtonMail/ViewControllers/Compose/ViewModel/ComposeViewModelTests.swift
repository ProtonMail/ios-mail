// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class ComposeViewModelTests: XCTestCase {
    private var mockCoreDataService: MockCoreDataContextProvider!
    private var apiMock: APIServiceMock!
    private var message: Message!
    private var testContext: NSManagedObjectContext!
    private var fakeUserManager: UserManager!
    private var sut: ComposeViewModel!
    private var contactProvider: MockContactProvider!
    private var dependencies: ComposeViewModel.Dependencies!
    private var notificationCenter: NotificationCenter!
    private var testContainer: TestContainer!
    private let userID: UserID = .init(String.randomString(20))
    private var mockUIDelegate: MockComposeUIProtocol!
    private var htmlEditor: HtmlEditorBehaviour!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = .init()
        LocaleEnvironment.locale = { .enGB }

        self.mockCoreDataService = MockCoreDataContextProvider()
        self.apiMock = APIServiceMock()
        self.notificationCenter = NotificationCenter()
        self.mockUIDelegate = MockComposeUIProtocol()
        self.htmlEditor = HtmlEditorBehaviour()

        testContext = MockCoreDataStore.testPersistentContainer.viewContext
        fakeUserManager = mockUserManager()
        contactProvider = .init(coreDataContextProvider: mockCoreDataService)

        let copyMessage = MockCopyMessageUseCase()

        copyMessage.executeStub.bodyIs { [unowned self] _, _ in
            (message, nil)
        }

        let helperDependencies = ComposerMessageHelper.Dependencies(
            messageDataService: fakeUserManager.messageService,
            cacheService: fakeUserManager.cacheService,
            contextProvider: mockCoreDataService,
            copyMessage: copyMessage
        )
        dependencies = ComposeViewModel.Dependencies(
            user: fakeUserManager,
            coreDataContextProvider: mockCoreDataService,
            fetchAndVerifyContacts: .init(),
            internetStatusProvider: MockInternetConnectionStatusProviderProtocol(),
            keychain: testContainer.keychain,
            fetchAttachment: .init(),
            contactProvider: contactProvider,
            helperDependencies: helperDependencies,
            fetchMobileSignatureUseCase: FetchMobileSignature(dependencies: .init(
                coreKeyMaker: MockKeyMakerProtocol(),
                cache: MockMobileSignatureCacheProtocol(),
                keychain: testContainer.keychain
            )),
            userDefaults: testContainer.userDefaults,
            notificationCenter: notificationCenter
        )

        self.message = testContext.performAndWait {
            Message(context: testContext)
        }

        sut = ComposeViewModel(
            remoteContentPolicy: .allowedThroughProxy,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        try sut.initialize(message: .init(message), action: .openDraft)
    }

    override func tearDown() {
        self.sut = nil
        self.mockCoreDataService = nil
        self.apiMock = nil
        self.message = nil
        self.testContext = nil
        self.notificationCenter = nil
        testContainer = nil
        self.mockUIDelegate = nil
        self.htmlEditor = nil
        FileManager.default.cleanTemporaryDirectory()
        LocaleEnvironment.restore()
        super.tearDown()
    }

    func testGetAttachment() {
        let attachment1 = Attachment(context: testContext)
        attachment1.order = 0
        attachment1.message = message
        let attachment2 = Attachment(context: testContext)
        attachment2.order = 1
        attachment2.message = message
        let attachmentSoftDeleted = Attachment(context: testContext)
        attachmentSoftDeleted.order = 3
        attachmentSoftDeleted.isSoftDeleted = true
        attachmentSoftDeleted.message = message

        let result = sut.getAttachments()
        // TODO: fix this test and uncomment this line, or replace the test, it's not meaningful
        // XCTAssertNotEqual(result, [])
        for index in result.indices {
            XCTAssertEqual(result[index].order, index)
        }
    }

    func testGetAddressesWhenMessageHeaderContainsFrom() {
        let addresses = generateAddress(number: 4)
        fakeUserManager.userInfo.set(addresses: addresses)

        let addressID = addresses[0].addressID
        let email1 = addresses[0].email
        let parts = email1.components(separatedBy: "@")
        let alias = "\(parts[0])+abcd@\(parts[1])"
        testContext.performAndWait {
            let obj = self.sut.composerMessageHelper.getRawMessageObject()
            obj?.parsedHeaders = "{\"From\": \"Tester <\(alias)>\"}"
        }
        let lists = sut.getAddresses()
        XCTAssertEqual(lists.count, 5)
        XCTAssertEqual(lists[0].email, "\(parts[0])+abcd@\(parts[1])")
        XCTAssertEqual(lists[0].addressID, addressID)
        XCTAssertEqual(lists.filter { $0.addressID == addressID }.count, 2)
    }

    func testGetAddresses_whenToHeaderIsCaseInsensitive_andHasAlias_itReturnsUserAddressWithAlias() {
        let addresses = generateAddress(number: 4)
        fakeUserManager.userInfo.set(addresses: addresses)

        let addressID = addresses[0].addressID
        let email1 = addresses[0].email
        let parts = email1.components(separatedBy: "@")
        let alias = "\(parts[0].uppercased())+abcd@\(parts[1])"
        testContext.performAndWait {
            let obj = self.sut.composerMessageHelper.getRawMessageObject()
            obj?.parsedHeaders = "{\"From\": \"Tester <\(alias)>\"}"
        }
        let lists = sut.getAddresses()
        XCTAssertEqual(lists.count, 5)
        XCTAssertEqual(lists[0].email, "\(parts[0])+abcd@\(parts[1])")
        XCTAssertEqual(lists[0].addressID, addressID)
        XCTAssertEqual(lists.filter { $0.addressID == addressID }.count, 2)
    }

    func testGetAddressesWhenMessageHeaderWithoutFrom() {
        let addresses = generateAddress(number: Int.random(in: 2...8))
        fakeUserManager.userInfo.set(addresses: addresses)

        let lists = sut.getAddresses()
        XCTAssertEqual(lists.count, addresses.count)
        XCTAssertEqual(lists, addresses)
    }
    
    func testInitializeAddress_whenReply_theOriginalToAddressIsInvalid_shouldUseDefaultAddress() throws {
        var addresses = generateAddress(number: 2)
        let invalidAddress = updateAddressStatus(address: addresses[0], status: .disabled)
        addresses[0] = invalidAddress
        fakeUserManager.userInfo.set(addresses: addresses)
        let aliasAddress = aliasAddress(from: addresses[0])
        
        message = mockCoreDataService.mainContext.performAndWait {
            let original = Message(context: self.mockCoreDataService.mainContext)
            original.messageID = UUID().uuidString
            original.parsedHeaders = "{\"X-Original-To\": \"\(aliasAddress.email)\"}"

            let repliedMessage = Message(context: self.mockCoreDataService.mainContext)
            repliedMessage.orginalMessageID = original.messageID
            return repliedMessage
        }

        try sut.initialize(message: .init(message), action: .reply)
        XCTAssertEqual(sut.currentSenderAddress(), fakeUserManager.addresses.defaultAddress())
    }
    
    func testInitializeAddress_whenReply_theOriginalToAddressIsValid_shouldUseIt() throws {
        let addresses = generateAddress(number: 2)
        fakeUserManager.userInfo.set(addresses: addresses)
        let aliasAddress = aliasAddress(from: addresses[0])
        
        message = mockCoreDataService.mainContext.performAndWait {
            let original = Message(context: self.mockCoreDataService.mainContext)
            original.messageID = UUID().uuidString
            original.parsedHeaders = "{\"X-Original-To\": \"\(aliasAddress.email)\"}"

            let repliedMessage = Message(context: self.mockCoreDataService.mainContext)
            repliedMessage.orginalMessageID = original.messageID
            return repliedMessage
        }

        try sut.initialize(message: .init(message), action: .reply)
        wait(self.sut.currentSenderAddress() == aliasAddress, timeout: 5)
    }
    
    func testAddressesStatusChanged_theCurrentAddressIsInvalid_shouldChangeToDefaultOne() throws {
        var addresses = generateAddress(number: 2)
        fakeUserManager.userInfo.set(addresses: addresses)
        let aliasAddress = aliasAddress(from: addresses[0])
        
        message = mockCoreDataService.mainContext.performAndWait {
            let original = Message(context: self.mockCoreDataService.mainContext)
            original.messageID = UUID().uuidString
            original.parsedHeaders = "{\"X-Original-To\": \"\(aliasAddress.email)\"}"

            let repliedMessage = Message(context: self.mockCoreDataService.mainContext)
            repliedMessage.orginalMessageID = original.messageID
            return repliedMessage
        }

        sut = ComposeViewModel(
            remoteContentPolicy: .allowedThroughProxy,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        try sut.initialize(message: .init(message), action: .reply)
        sut.uiDelegate = mockUIDelegate
        wait(self.sut.currentSenderAddress() == aliasAddress, timeout: 5)
        
        let invalidAddress = updateAddressStatus(address: addresses[0], status: .disabled)
        addresses[0] = invalidAddress
        fakeUserManager.userInfo.set(addresses: addresses)
        let ex = expectation(description: "Change event is called")
        mockUIDelegate.changeInvalidSenderAddressStub.bodyIs { _, newAddress  in
            XCTAssertEqual(newAddress, addresses[1])
            ex.fulfill()
        }
        notificationCenter.post(name: .addressesStatusAreChanged, object: nil)
        wait(for: [ex], timeout: 5)
    }

    // MARK: isEmptyDraft tests

    func testIsEmptyDraft_messageInit() throws {
        try sut.initialize(message: .init(message), action: .openDraft)
        XCTAssertTrue(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_subjectField() throws {
        message.title = "abc"
        try sut.initialize(message: .init(message), action: .openDraft)
        XCTAssertFalse(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_recipientField() throws {
        message.toList = "[]"
        message.ccList = "[]"
        message.bccList = "[]"
        try sut.initialize(message: .init(message), action: .openDraft)

        XCTAssertTrue(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_whenBodyHasNoTextOrImages_itShouldReturnTrue() throws {
        message.body = "<div><br></div><div><br></div></body>"
        try sut.initialize(message: .init(message), action: .openDraft)

        XCTAssertTrue(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_whenBodyOnlyHasText_itShouldReturnFalse() throws {
        message.body =
        """
        <body>
        <div>
         <br>
        </div>
        <div dir="auto">
         Hey there
        </div>
        </body>
        """
        try sut.initialize(message: .init(message), action: .openDraft)

        XCTAssertFalse(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_whenBodyOnlyHasImages_itShouldReturnFalse() throws {
        message.body =
        """
        <body>
        <div>
         <br>
        </div>
        <div dir="auto">
         <br>
         <img src-original-pm-cid="cid:b5480987_image.jpeg" src="cid:b5480987_image.jpeg">
        </div>
        </body>
        """
        try sut.initialize(message: .init(message), action: .openDraft)

        XCTAssertFalse(sut.isEmptyDraft())
    }

    func testDecodingRecipients_prefersMatchingLocalContactName() throws {
        let email = EmailEntity.make(contactName: "My friend I don't like")

        contactProvider.getEmailsByAddressStub.bodyIs { _, _ in
            [email]
        }

        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend I don't like")
    }

    func testDecodingRecipients_usesBackendName_ifNoLocalContact() throws {
        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend")
    }

    func testDecodingRecipients_usesEmailAsDisplayName_ifNothingElseIsFound() throws {
        let backendResponsesWithoutProperName: [String] = [
            "[{\"Address\": \"friend@example.com\", \"Name\": \" \", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Name\": \"\", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Group\": \"\"}]"
        ]

        for backendResponse in backendResponsesWithoutProperName {
            let contacts = sut.toContacts(backendResponse)
            let contact = try XCTUnwrap(contacts.first)
            XCTAssertEqual(contact.displayName, "friend@example.com")
        }
    }

    func testInit_withFileData_stripMetaDataIsOn_attachmentHasNoGPSData() throws {
        let fileData = try loadImage(fileName: "IMG_0001")
        testContainer.keychain[.metadataStripping] = .stripMetadata
        sut = .init(
            subject: "",
            body: "",
            files: [fileData],
            action: .newDraftFromShare,
            dependencies: dependencies
        )

        sut.insertImportedFiles(in: htmlEditor)

        var imageUrl: URL?
        mockCoreDataService.performAndWaitOnRootSavingContext { context in
            let msg = self.sut.composerMessageHelper.getRawMessageObject()
            XCTAssertFalse(msg?.attachments.count == 0)
            let attachment = (msg?.attachments.allObjects as? [Attachment])?.first
            imageUrl = attachment?.localURL
        }
        let urlToLoad = try XCTUnwrap(imageUrl)
        XCTAssertFalse(urlToLoad.hasGPSData())
    }

    // TODO: test stripMetadata case 

    func testInit_whenReplyAll_shouldRespectReplyToField() throws {
        self.message = testContext.performAndWait {
            let message = Message(context: testContext)
            message.replyTos = "[{\"Address\":\"tester@pm.test\",\"Name\":\"abc\",\"BimiSelector\":null,\"IsProton\":0,\"DisplaySenderImage\":0,\"IsSimpleLogin\":0}]"
            message.toList = #"""
[
    {
        "Address": "tester@pm.test",
        "Name": "tester"
    },
    {
        "Address": "tester002@pm.test",
        "Name": "tester002"
    },
    {
        "Address": "tester003@pm.test",
        "Name": "tester003"
    }
]
"""#
            message.ccList = #"""
[
    {
        "Address": "ccTester@pm.test",
        "Name": "ccTester"
    },
    {
        "Address": "ccTester002@pm.test",
        "Name": "ccTester002"
    }
]
"""#
            return message
        }

        try sut.initialize(message: .init(message), action: .replyAll)
        sut.collectDraft("", body: "", expir: 0, pwd: "", pwdHit: "")
        let draft = try XCTUnwrap(sut.composerMessageHelper.draft)
        
        let toList = sut.toContacts(draft.recipientList)
        XCTAssertEqual(toList.count, 1)
        XCTAssertEqual(toList.first?.displayEmail, "tester@pm.test")
        
        let ccList = sut.toContacts(draft.ccList)
        XCTAssertEqual(ccList.count, 4)
        let mails = ccList.compactMap(\.displayEmail)
        XCTAssertEqual(mails, ["tester002@pm.test", "tester003@pm.test", "ccTester@pm.test", "ccTester002@pm.test"])
        
        let bccList = sut.toContacts(draft.bccList)
        XCTAssertEqual(bccList.count, 0)
    }

	func testFetchContacts_newEmailAdded_contactsWillHaveNewlyAddedEmail() throws {
        sut.fetchContacts()
        XCTAssertTrue(sut.contacts.isEmpty)
        let name = String.randomString(20)
        let address = "\(String.randomString(20))@pm.me"

        _ = try mockCoreDataService.write { context in
            let email = Email(context: context)
            email.userID = self.sut.user.userID.rawValue
            email.name = name
            email.email = address
            email.contactID = String.randomString(20)
            email.emailID = String.randomString(20)
            let OtherUserEmail = Email(context: context)
            OtherUserEmail.userID = String.randomString(20)
            OtherUserEmail.name = String.randomString(20)
            OtherUserEmail.email = String.randomString(20)
            OtherUserEmail.contactID = String.randomString(20)
            OtherUserEmail.emailID = String.randomString(20)
        }

        wait(!self.sut.contacts.isEmpty)

        let newEmail = try XCTUnwrap(sut.contacts.first)
        XCTAssertEqual(newEmail.displayName, name)
        XCTAssertEqual(newEmail.displayEmail, address)
    }

    func testFetchContacts_newEmailAdded_withContactCombine_contactsWillHaveAllNewlyAddedEmail() throws {
        testContainer.userDefaults[.isCombineContactOn] = true
        sut.fetchContacts()
        XCTAssertTrue(sut.contacts.isEmpty)
        let name = String.randomString(20)
        let address = "\(String.randomString(20))@pm.me"
        let name2 = String.randomString(20)
        let address2 = "\(String.randomString(20))@pm.me"

        _ = try mockCoreDataService.write { context in
            let email = Email(context: context)
            email.userID = self.sut.user.userID.rawValue
            email.name = name
            email.email = address
            email.contactID = String.randomString(20)
            email.emailID = String.randomString(20)
            let OtherUserEmail = Email(context: context)
            OtherUserEmail.userID = String.randomString(20)
            OtherUserEmail.name = name2
            OtherUserEmail.email = address2
            OtherUserEmail.contactID = String.randomString(20)
            OtherUserEmail.emailID = String.randomString(20)
        }

        wait(!self.sut.contacts.isEmpty)

        XCTAssertEqual(sut.contacts.count, 2)

        let newEmail = try XCTUnwrap(sut.contacts.first(where: { $0.displayName == name } ))
        XCTAssertEqual(newEmail.displayName, name)
        XCTAssertEqual(newEmail.displayEmail, address)

        let newEmail2 = try XCTUnwrap(sut.contacts.first(where: { $0.displayName == name2 } ))
        XCTAssertEqual(newEmail2.displayName, name2)
        XCTAssertEqual(newEmail2.displayEmail, address2)
    }

    func testLoadingPolicy_whenImagePixelIsDisabled_contentLoadingTypeShouldBeSkipProxy_remoteContentShouldNotThroughProxy() {
        fakeUserManager.userInfo.imageProxy = .none
        var (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .skipProxy)
        XCTAssertEqual(remoteContentMode, .allowedWithoutProxy)

        sut = ComposeViewModel(
            remoteContentPolicy: .allowedWithoutProxy,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .skipProxy)
        XCTAssertEqual(remoteContentMode, .allowedWithoutProxy)
    }

    func testLoadingPolicy_whenImagePixelIsEnabled_contentLoadingTypeShouldBeProsy_remoteContentShouldThroughProxy() {
        fakeUserManager.userInfo.imageProxy = .imageProxy
        var (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .proxy)
        XCTAssertEqual(remoteContentMode, .allowedThroughProxy)

        sut = ComposeViewModel(
            remoteContentPolicy: .allowedWithoutProxy,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .proxy)
        XCTAssertEqual(remoteContentMode, .allowedThroughProxy)
    }

    func testLoadingPolicy_whenPreferredRemoteContentIsDisabled_itAlwaysReturnsDisabled() {
        fakeUserManager.userInfo.imageProxy = .imageProxy
        sut = ComposeViewModel(
            remoteContentPolicy: .disallowed,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        var (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .proxy)
        XCTAssertEqual(remoteContentMode, .disallowed)

        fakeUserManager.userInfo.imageProxy = .none
        sut = ComposeViewModel(
            remoteContentPolicy: .disallowed,
            embeddedContentPolicy: .allowed,
            dependencies: dependencies
        )
        (contentLoadingType, remoteContentMode) = sut.loadingPolicy()
        XCTAssertEqual(contentLoadingType, .skipProxy)
        XCTAssertEqual(remoteContentMode, .disallowed)
    }

    func testShouldShowSenderChangedAlertDueToDisableAddress() throws {
        var addresses = generateAddress(number: 2)
        let invalidAddress = updateAddressStatus(address: addresses[0], status: .disabled)
        addresses[0] = invalidAddress
        fakeUserManager.userInfo.set(addresses: addresses)
        let aliasAddress = aliasAddress(from: addresses[0])

        message = mockCoreDataService.mainContext.performAndWait {
            let original = Message(context: self.mockCoreDataService.mainContext)
            original.messageID = UUID().uuidString
            original.parsedHeaders = "{\"X-Original-To\": \"\(aliasAddress.email)\"}"

            let repliedMessage = Message(context: self.mockCoreDataService.mainContext)
            repliedMessage.orginalMessageID = original.messageID
            return repliedMessage
        }

        try sut.initialize(message: .init(message), action: .reply)
        XCTAssertEqual(sut.currentSenderAddress(), fakeUserManager.addresses.defaultAddress())
        XCTAssertEqual(sut.originalSenderAddress(), aliasAddress)

        XCTAssertTrue(sut.shouldShowSenderChangedAlertDueToDisabledAddress())
    }

    func testShouldShowErrorWhenOriginalAddressIsAnUnpaidPMAddress() throws {
        var addresses = generateAddress(number: 2)
        let pmAddress = updateAddressStatus(
            address: addresses[0],
            status: .enabled,
            email: "test@pm.me",
            send: .inactive
        )
        addresses[0] = pmAddress
        fakeUserManager.userInfo.set(addresses: addresses)

        message = mockCoreDataService.mainContext.performAndWait {
            let original = Message(context: self.mockCoreDataService.mainContext)
            original.messageID = UUID().uuidString
            original.parsedHeaders = "{\"X-Original-To\": \"\(pmAddress.email)\"}"

            let repliedMessage = Message(context: self.mockCoreDataService.mainContext)
            repliedMessage.orginalMessageID = original.messageID
            repliedMessage.sender = "{\"Address\": \"\(addresses[1].email)\", \"Name\": \"Test\"}"
            return repliedMessage
        }

        try sut.initialize(message: .init(message), action: .reply)
        XCTAssertEqual(sut.currentSenderAddress(), fakeUserManager.addresses.defaultSendAddress())
        XCTAssertEqual(sut.originalSenderAddress(), pmAddress)

        XCTAssertTrue(sut.shouldShowErrorWhenOriginalAddressIsAnUnpaidPMAddress())
    }

    // TODO: fix it
//    func testGetHtmlBody_replyAction_checkTheQuotedDataIsCorrect() {
//        message.sender = "{\"BimiSelector\":null,\"IsSimpleLogin\":0,\"IsProton\":0,\"Address\":\"oldSender@pm.test\",\"Name\":\"old sender\",\"DisplaySenderImage\":0}"
//        message.orginalTime = Date(timeIntervalSince1970: 1699509498)
//        sut.initialize(message: .init(message), action: .reply)
//        let content = sut.getHtmlBody()
//        let body = content.body
//        let expected = " <html><head></head><body>  <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from <a href=\"https://proton.me/mail/home\">Proton Mail</a> for iOS</div></div> <div><br></div><div><br></div>On Thu, Nov 9, 2023 at 1:58 PM, old sender &lt;<a href=\"mailto:On Thu, Nov 9, 2023 at 1:58 PM, old sender &lt;<a href=\"mailto:old sender\" class=\"\">oldSender@pm.test</a>&gt; wrote:</div><blockquote class=\"protonmail_quote\" type=\"cite\">  <div><pre></pre></div></blockquote></body></html>"
//        XCTAssertEqual(body, expected)
//    }

//    func testGetHtmlBody_forwardAction_checkTheQuotedDataIsCorrect() {
//        message.title = "I am a subject"
//        message.orginalTime = Date(timeIntervalSince1970: 1699509498)
//        message.sender = "{\"BimiSelector\":null,\"IsSimpleLogin\":0,\"IsProton\":0,\"Address\":\"oldSender@pm.test\",\"Name\":\"old sender\",\"DisplaySenderImage\":0}"
//        sut.initialize(message: .init(message), action: .forward)
//        let content = sut.getHtmlBody()
//        let body = content.body
//        let expected = "<html><head></head><body> <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from <a href=\"https://proton.me/mail/home\">Proton Mail</a> for iOS</div></div><div><br></div><div><br></div><blockquote class=\"protonmail_quote\" type=\"cite\">---------- Forwarded message ----------<br>From: old sender &lt;<a href=\"mailto:oldSender@pm.test\" class=\"\">oldSender@pm.test</a>&gt;<br>Date: On Thu, Nov 9, 2023 at 1:58 PM<br>Subject: Fw: I am a subject<br></div> <div><pre></pre></div></body></html>"
//        XCTAssertEqual(body, expected)
//    }
}

extension ComposeViewModelTests {
    private func mockUserManager() -> UserManager {
        let userInfo = UserInfo.getDefault()
        userInfo.defaultSignature = "Hi"
        userInfo.userId = self.userID.rawValue
        let key = Key(keyID: "keyID", privateKey: KeyTestData.privateKey1)
        let address = Address(addressID: UUID().uuidString,
                              domainID: "",
                              email: "",
                              send: .active,
                              receive: .active,
                              status: .enabled,
                              type: .protonDomain,
                              order: 0,
                              displayName: "the name",
                              signature: "Hello",
                              hasKeys: 1,
                              keys: [key])
        userInfo.set(addresses: [address])
        return UserManager(api: apiMock, userInfo: userInfo)
    }

    func generateAddress(number: Int) -> [Address] {
        let key = Key(keyID: "keyID", privateKey: KeyTestData.privateKey1)
        let list = (0..<number).map { index in
            let id = UUID().uuidString
            let domain = "\(String.randomString(3)).\(String.randomString(3))"
            let userPart = String.randomString(5)
            return Address(
                addressID: id,
                domainID: UUID().uuidString,
                email: "\(userPart)@\(domain)".lowercased(),
                send: .active,
                receive: .active,
                status: .enabled,
                type: .protonDomain,
                order: 0,
                displayName: String.randomString(7),
                signature: "Hello",
                hasKeys: 1,
                keys: [key]
            )
        }
        return list
    }
    
    func updateAddressStatus(
        address: Address,
        status: Address.AddressStatus,
        email: String? = nil,
        send: Address.AddressSendReceive? = nil
    ) -> Address {
        return Address(
            addressID: address.addressID,
            domainID: address.domainID,
            email: email ?? address.email,
            send: send ?? address.send,
            receive: address.receive,
            status: status,
            type: address.type,
            order: address.order,
            displayName: address.displayName,
            signature: address.signature,
            hasKeys: address.hasKeys,
            keys: address.keys
        )
    }
    
    func aliasAddress(from address: Address) -> Address {
        let email = address.email
        let splits = email.components(separatedBy: "@")
        let alias = "\(splits[0])+alias@\(splits[1])"
        return Address(
            addressID: address.addressID,
            domainID: address.domainID,
            email: alias,
            send: address.send,
            receive: address.receive,
            status: address.status,
            type: address.type,
            order: address.order,
            displayName: address.displayName,
            signature: address.signature,
            hasKeys: address.hasKeys,
            keys: address.keys
        )
    }

    private func loadImage(fileName: String) throws -> ConcreteFileData {
        let bundle = Bundle.init(for: Self.self)
        let fullFileName = "\(fileName).JPG"
        let jpgUrl = try XCTUnwrap(bundle.url(forResource: fileName, withExtension: "JPG"))
        let data = try Data(contentsOf: jpgUrl)
        let url = try FileManager.default.createTempURL(forCopyOfFileNamed: fullFileName)
        try data.write(to: url)
        return ConcreteFileData(
            name: fullFileName,
            mimeType: "image/jpg",
            contents: url
        )
    }
}

private extension URL {
    func hasGPSData() -> Bool {
        guard let source = CGImageSourceCreateWithURL(self as CFURL, nil),
              let metaData = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return false
        }
        return metaData[kCGImagePropertyGPSDictionary as String] != nil
    }
}
