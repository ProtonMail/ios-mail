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

import XCTest

@testable import ProtonMail

class NewMessageBodyViewModelTests: XCTestCase {
    private var sut: NewMessageBodyViewModel!
    private var newMessageBodyViewModelDelegateMock: NewMessageBodyViewModelDelegateMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let reachabilityStub = ReachabilityStub()
        let internetConnectionStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)
        sut = NewMessageBodyViewModel(spamType: nil,
                                      internetStatusProvider: internetConnectionStatusProviderMock,
                                      linkConfirmation: .openAtWill)
        newMessageBodyViewModelDelegateMock = NewMessageBodyViewModelDelegateMock()
        sut.delegate = newMessageBodyViewModelDelegateMock
    }

    override func tearDown() {
        sut = nil
        newMessageBodyViewModelDelegateMock = nil

        super.tearDown()
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

        sut.update(renderStyle: .lightOnly)
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

}
