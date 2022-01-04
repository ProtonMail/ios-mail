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
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        testContext = coreDataService.rootSavingContext
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
        sut = NewMessageBodyViewModel(message: messageStub,
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
        XCTAssertEqual(sut.remoteContentPolicy, WebContents.RemoteContentPolicy.disallowed.rawValue)
        XCTAssertEqual(sut.embeddedContentPolicy, .disallowed)

        sut = NewMessageBodyViewModel(message: messageStub,
                                      messageDataProcessor: messageDataProcessMock,
                                      userAddressUpdater: userAddressUpdaterMock,
                                      shouldAutoLoadRemoteImages: true,
                                      shouldAutoLoadEmbeddedImages: true,
                                      internetStatusProvider: internetConnectionStatusProviderMock,
                                      isDarkModeEnableClosure: {
            return self.isDarkModeEnableStub
        },
                                      linkConfirmation: .openAtWill)
        XCTAssertEqual(sut.remoteContentPolicy, WebContents.RemoteContentPolicy.allowed.rawValue)
        XCTAssertEqual(sut.embeddedContentPolicy, .allowed)
    }

    func testReloadMessageWith() {
        XCTAssertEqual(sut.currentMessageRenderStyle, .dark)
        XCTAssertNil(sut.contents)
        sut.messageHasChanged(message: messageStub)
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

    func testShouldDisplayRenderModeOptions() {
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, isDarkModeEnableStub)
        isDarkModeEnableStub.toggle()
        XCTAssertEqual(sut.shouldDisplayRenderModeOptions, isDarkModeEnableStub)
    }
}
