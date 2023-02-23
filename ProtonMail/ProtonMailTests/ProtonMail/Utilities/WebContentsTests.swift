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

class WebContentsTests: XCTestCase {

    var sut: WebContents!
    override func setUp() {
        super.setUp()

    }

    override func tearDown() {
        sut = nil
    }

    func testInit() {
        let testBody = "body"
        sut = WebContents(body: testBody, remoteContentMode: .allowed, renderStyle: .dark)
        XCTAssertEqual(sut.body, testBody)
        XCTAssertEqual(sut.remoteContentMode, .allowed)
        XCTAssertEqual(sut.renderStyle, .dark)
    }

    func testContentSecurityPolicy() {
        sut = WebContents(body: "testBody", remoteContentMode: .allowed)
        let scheme = HTTPRequestSecureLoader.imageCacheScheme
        XCTAssertEqual(sut.contentSecurityPolicy, "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid: \(scheme):; script-src 'none';")

        sut = WebContents(body: "testBody", remoteContentMode: .disallowed)
        XCTAssertEqual(sut.contentSecurityPolicy, "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data: blob: \(scheme):; script-src 'none';")

        sut = WebContents(body: "testBody", remoteContentMode: .lockdown)
        XCTAssertEqual(sut.contentSecurityPolicy, "default-src 'none'; style-src 'self' 'unsafe-inline';")
    }

    func testBodyForJS() {
        let testBody = " <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from ProtonMail for iOS</div></div>"
        let result = "\\u0020\\u003C\\u0064\\u0069\\u0076\\u003E\\u003C\\u0062\\u0072\\u003E\\u003C\\u002F\\u0064\\u0069\\u0076\\u003E\\u003C\\u0064\\u0069\\u0076\\u003E\\u003C\\u0062\\u0072\\u003E\\u003C\\u002F\\u0064\\u0069\\u0076\\u003E\\u0020\\u003C\\u0064\\u0069\\u0076\\u0020\\u0069\\u0064\\u003D\\u0022\\u0070\\u0072\\u006F\\u0074\\u006F\\u006E\\u006D\\u0061\\u0069\\u006C\\u005F\\u006D\\u006F\\u0062\\u0069\\u006C\\u0065\\u005F\\u0073\\u0069\\u0067\\u006E\\u0061\\u0074\\u0075\\u0072\\u0065\\u005F\\u0062\\u006C\\u006F\\u0063\\u006B\\u0022\\u003E\\u003C\\u0064\\u0069\\u0076\\u003E\\u0053\\u0065\\u006E\\u0074\\u0020\\u0066\\u0072\\u006F\\u006D\\u0020\\u0050\\u0072\\u006F\\u0074\\u006F\\u006E\\u004D\\u0061\\u0069\\u006C\\u0020\\u0066\\u006F\\u0072\\u0020\\u0069\\u004F\\u0053\\u003C\\u002F\\u0064\\u0069\\u0076\\u003E\\u003C\\u002F\\u0064\\u0069\\u0076\\u003E"
        sut = WebContents(body: testBody, remoteContentMode: .allowed)
        XCTAssertEqual(sut.bodyForJS, result)
    }
}
