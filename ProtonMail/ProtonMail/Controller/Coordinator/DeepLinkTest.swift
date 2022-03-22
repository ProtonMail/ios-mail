//
//  DeepLinkTest.swift
//  ProtonMail - Created on 12/13/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail

class DeepLinkTests: XCTestCase {
    func makeDeeplink() -> DeepLink {
        let head = DeepLink("Head", sender: #file)
        head.append(.init(name: "String"))
        head.append(.init(name: "Path"))
        head.append(.init(name: "String+sender", value: #file))
        head.append(.init(name: "Path+sender", value: #file))
        return head
    }

    func testDescription() {
        let deeplink = self.makeDeeplink()
        XCTAssertFalse(deeplink.debugDescription.isEmpty)
    }

    func testPopFirst() {
        let deeplink = self.makeDeeplink()
        let oldHead = deeplink.head
        let oldSecond = deeplink.head?.next

        XCTAssertEqual(oldHead, deeplink.popFirst)
        XCTAssertEqual(oldSecond, deeplink.head)
    }

    func testPopLast() {
        let deeplink = self.makeDeeplink()
        let oldPreLast = deeplink.last?.previous
        let oldLast = deeplink.last

        XCTAssertEqual(oldLast, deeplink.popLast)
        XCTAssertEqual(oldPreLast, deeplink.last)
    }

    func testContains() {
        let deeplink = self.makeDeeplink()
        let one = DeepLink.Node(name: "String+sender", value: #file)
        let other = DeepLink.Node(name: "Nonce", value: #file)

        XCTAssertTrue(deeplink.contains(one))
        XCTAssertFalse(deeplink.contains(other))

        deeplink.append(other)

        XCTAssertTrue(deeplink.contains(one))
        XCTAssertTrue(deeplink.contains(other))
    }

    func testCutUntil() {
        let one = DeepLink.Node(name: "one", value: #file)
        let two = DeepLink.Node(name: "two", value: #file)
        let three = DeepLink.Node(name: "three", value: #file)
        let four = DeepLink.Node(name: "four", value: #file)
        let other = DeepLink.Node(name: "Nonce", value: #file)

        let deeplink = DeepLink("zero")
        [one, two, three, four].forEach(deeplink.append)

        //
        deeplink.cut(until: other)
        XCTAssertTrue(deeplink.contains(one))
        XCTAssertTrue(deeplink.contains(two))
        XCTAssertTrue(deeplink.contains(three))
        XCTAssertTrue(deeplink.contains(four))

        //

        deeplink.cut(until: two)
        XCTAssertTrue(deeplink.contains(one))
        XCTAssertTrue(deeplink.contains(two))
        XCTAssertFalse(deeplink.contains(three))
        XCTAssertFalse(deeplink.contains(four))
    }
}
