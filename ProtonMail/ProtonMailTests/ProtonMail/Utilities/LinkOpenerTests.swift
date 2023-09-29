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

import XCTest

@testable import ProtonMail

final class LinkOpenerTests: XCTestCase {

    func testHttpsDeeplinks() throws {
        let testURL = try XCTUnwrap(URL(string: "https://example.com/pathcomponent?query=param"))

        let expectedURLs: [LinkOpener: String] = [
            .brave: "brave://open-url?url=https%3A//example.com/pathcomponent?query%3Dparam",
            .chrome: "googlechromes://example.com/pathcomponent?query=param",
            .duckDuckGo: "ddgQuickLink://example.com/pathcomponent?query=param",
            .edge: "microsoft-edge-https://example.com/pathcomponent?query=param",
            .firefox: "firefox://open-url?url=https%3A//example.com/pathcomponent?query%3Dparam",
            .firefoxFocus: "firefox-focus://open-url?url=https%3A//example.com/pathcomponent?query%3Dparam",
            .inAppSafari: "https://example.com/pathcomponent?query=param",
            .onion: "onionhttps://example.com/pathcomponent?query=param",
            .operaMini: "opera-https://example.com/pathcomponent?query=param",
            .operaTouch: "touch-https://example.com/pathcomponent?query=param",
            .safari: "https://example.com/pathcomponent?query=param",
            .yandex: "yandexbrowser-open-url://https%3A%2F%2Fexample.com%2Fpathcomponent%3Fquery=param"
        ]

        for (linkOpener, expectedURLString) in expectedURLs {
            let expectedURL = try XCTUnwrap(URL(string: expectedURLString))
            let deeplink = linkOpener.deeplink(to: testURL)
            XCTAssertEqual(deeplink, expectedURL)
        }
    }

    func testHttpDeeplinks() throws {
        let testURL = try XCTUnwrap(URL(string: "http://example.com/pathcomponent?query=param"))

        let expectedURLs: [LinkOpener: String] = [
            .brave: "brave://open-url?url=http%3A//example.com/pathcomponent?query%3Dparam",
            .chrome: "googlechrome://example.com/pathcomponent?query=param",
            .duckDuckGo: "ddgQuickLink://example.com/pathcomponent?query=param",
            .edge: "microsoft-edge-http://example.com/pathcomponent?query=param",
            .firefox: "firefox://open-url?url=http%3A//example.com/pathcomponent?query%3Dparam",
            .firefoxFocus: "firefox-focus://open-url?url=http%3A//example.com/pathcomponent?query%3Dparam",
            .inAppSafari: "http://example.com/pathcomponent?query=param",
            .onion: "onionhttp://example.com/pathcomponent?query=param",
            .operaMini: "opera-http://example.com/pathcomponent?query=param",
            .operaTouch: "touch-http://example.com/pathcomponent?query=param",
            .safari: "http://example.com/pathcomponent?query=param",
            .yandex: "yandexbrowser-open-url://http%3A%2F%2Fexample.com%2Fpathcomponent%3Fquery=param"
        ]

        for (linkOpener, expectedURLString) in expectedURLs {
            let expectedURL = try XCTUnwrap(URL(string: expectedURLString))
            let deeplink = linkOpener.deeplink(to: testURL)
            XCTAssertEqual(deeplink, expectedURL)
        }
    }
}
