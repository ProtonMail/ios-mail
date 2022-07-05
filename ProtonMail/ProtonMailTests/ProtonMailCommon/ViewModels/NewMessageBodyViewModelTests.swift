// Copyright (c) 2021 Proton AG
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

import CoreData
import Groot
import XCTest
@testable import ProtonMail

class NewMessageBodyViewModelTests: XCTestCase {

    var sut: NewMessageBodyViewModel!
    var messageDataProcessMock: MessageDataProcessMock!
    var userAddressUpdaterMock: UserAddressUpdaterProtocol!
    var reachabilityStub: ReachabilityStub!
    var internetConnectionStatusProviderMock: InternetConnectionStatusProvider!
    var messageStub: Message!

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!
    var isDarkModeEnableStub: Bool = false
    var newMessageBodyViewModelDelegateMock: NewMessageBodyViewModelDelegateMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        testContext = coreDataService.mainContext
        let parsedObject = testMessageDetailData.parseObjectAny()!
        messageStub = try GRTJSONSerialization.object(withEntityName: "Message",
                                                      fromJSONDictionary: parsedObject, in: testContext) as? Message
        messageStub.userID = "userID"
        messageStub.isDetailDownloaded = true
        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: parsedLabel, in: testContext)
        try testContext.save()

        messageDataProcessMock = MessageDataProcessMock()
        userAddressUpdaterMock = UserAddressUpdapterMock()

        reachabilityStub = ReachabilityStub()
        internetConnectionStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)
        sut = NewMessageBodyViewModel(message: MessageEntity(messageStub),
                                      messageDataProcessor: messageDataProcessMock,
                                      userAddressUpdater: userAddressUpdaterMock,
                                      shouldAutoLoadRemoteImages: false,
                                      shouldAutoLoadEmbeddedImages: false,
                                      internetStatusProvider: internetConnectionStatusProviderMock,
                                      isDarkModeEnableClosure: {
            return self.isDarkModeEnableStub
        },
                                      linkConfirmation: .openAtWill)
        newMessageBodyViewModelDelegateMock = NewMessageBodyViewModelDelegateMock()
        sut.delegate = newMessageBodyViewModelDelegateMock
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInit() {
        XCTAssertEqual(sut.remoteContentPolicy, .disallowed)
        XCTAssertEqual(sut.embeddedContentPolicy, .disallowed)

        sut = NewMessageBodyViewModel(message: MessageEntity(messageStub),
                                      messageDataProcessor: messageDataProcessMock,
                                      userAddressUpdater: userAddressUpdaterMock,
                                      shouldAutoLoadRemoteImages: true,
                                      shouldAutoLoadEmbeddedImages: true,
                                      internetStatusProvider: internetConnectionStatusProviderMock,
                                      isDarkModeEnableClosure: {
            return self.isDarkModeEnableStub
        },
                                      linkConfirmation: .openAtWill)
        XCTAssertEqual(sut.remoteContentPolicy, .allowed)
        XCTAssertEqual(sut.embeddedContentPolicy, .allowed)
    }

    func testReloadMessageWith() {
        XCTAssertEqual(sut.currentMessageRenderStyle, .dark)
        XCTAssertNil(sut.contents)
        sut.messageHasChanged(message: MessageEntity(messageStub))
        XCTAssertNotNil(sut.contents)
        XCTAssertEqual(sut.contents?.renderStyle, .dark)

        sut.reloadMessageWith(style: .lightOnly)
        XCTAssertEqual(sut.currentMessageRenderStyle, .lightOnly)
        XCTAssertEqual(sut.contents?.renderStyle, .lightOnly)
        XCTAssertTrue(newMessageBodyViewModelDelegateMock.isReloadWebViewCalled)
    }

    func testSetDisplayMode() {
        XCTAssertEqual(sut.displayMode, .collapsed)
        XCTAssertFalse(newMessageBodyViewModelDelegateMock.isReloadWebViewCalled)
        sut.displayMode = .expanded
        XCTAssertTrue(newMessageBodyViewModelDelegateMock.isReloadWebViewCalled)
    }

    func testPlaceholderContent() {
        XCTAssertEqual(sut.currentMessageRenderStyle, .dark)
        let meta = "<meta name=\"viewport\" content=\"width=device-width\">"
        let expected = """
                            <html><head>\(meta)<style type='text/css'>
                            \(WebContents.css)</style>
                            </head><body>\(LocalString._loading_)</body></html>
                         """
        XCTAssertEqual(sut.placeholderContent, expected)

        sut.reloadMessageWith(style: .lightOnly)
        XCTAssertEqual(sut.currentMessageRenderStyle, .lightOnly)
        let expected1 = """
                            <html><head>\(meta)<style type='text/css'>
                            \(WebContents.cssLightModeOnly)</style>
                            </head><body>\(LocalString._loading_)</body></html>
                         """
        XCTAssertEqual(sut.placeholderContent, expected1)
    }

    func testGetWebViewPreference() {
        XCTAssertFalse(sut.webViewPreferences.javaScriptEnabled)
        XCTAssertFalse(sut.webViewPreferences.javaScriptCanOpenWindowsAutomatically)
    }

    func testGetWebViewConfig() {
        XCTAssertEqual(sut.webViewConfig.dataDetectorTypes, [.phoneNumber, .link])
    }

    func testShouldDisplayRenderModeOptions_notSupportDarkMode() {
        // Not support due to contain !important
        let body = "<html><body style=\"bgcolor: white !important\">hi</body></html>"
        sut.setupBodyPartForTest(isNewsLetter: false, body: body)
        isDarkModeEnableStub.toggle()
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, false)
    }

    func testShouldDisplayRenderModeOptions_senderSupport() {
        // Sender support due to contain prefers-color-scheme
        let body = "<html><head> <style>@media (prefers-color-scheme: dark){}</style></head><body> hi</body></html>"
        sut.setupBodyPartForTest(isNewsLetter: false, body: body)
        isDarkModeEnableStub.toggle()
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, false)
    }

    func testShouldDisplayRenderModeOptions_newsletter() {
        let body = "<html><head></head><body> hi</body></html>"
        sut.setupBodyPartForTest(isNewsLetter: true, body: body)
        isDarkModeEnableStub.toggle()
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, false)
    }

    func testShouldDisplayRenderModeOptions_commonCase() {
        let body = "<html><head></head><body> hi</body></html>"
        sut.setupBodyPartForTest(isNewsLetter: false, body: body)
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, isDarkModeEnableStub)
        isDarkModeEnableStub.toggle()
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, isDarkModeEnableStub)
    }

    func testSendMetricAPIIfNeeded() throws {
        guard #available(iOS 12.0, *) else { return }
        self.newMessageBodyViewModelDelegateMock.interfaceStyle = .light
        self.sut.sendMetricAPIIfNeeded()
        XCTAssertNil(self.newMessageBodyViewModelDelegateMock.isApplyDarkStyle)

        // light mode only
        self.newMessageBodyViewModelDelegateMock.interfaceStyle = .dark
        var content = WebContents(body: "", remoteContentMode: .allowed, renderStyle: .lightOnly, supplementCSS: nil)
        self.sut.sendMetricAPIIfNeeded(contents: content)
        XCTAssertNil(self.newMessageBodyViewModelDelegateMock.isApplyDarkStyle)

        content = WebContents(body: "", remoteContentMode: .allowed, renderStyle: .dark, supplementCSS: "")
        self.sut.sendMetricAPIIfNeeded(contents: content)
        let flag = try XCTUnwrap(self.newMessageBodyViewModelDelegateMock.isApplyDarkStyle)
        XCTAssertTrue(flag)
    }

    func testSendMetricAPIIfNeeded_reload() {
        guard #available(iOS 12.0, *) else { return }
        self.newMessageBodyViewModelDelegateMock.interfaceStyle = .dark
        self.sut.reloadMessageWith(style: .lightOnly)
        if let flag = self.newMessageBodyViewModelDelegateMock.isApplyDarkStyle {
            XCTAssertFalse(flag)
        } else {
            XCTFail("Should have the flag")
        }
    }
}
