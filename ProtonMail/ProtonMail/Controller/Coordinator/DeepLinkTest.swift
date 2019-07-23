//
//  DeepLinkTest.swift
//  ProtonMail - Created on 12/13/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import XCTest
@testable import ProtonMail

class DeepLinkTests: XCTestCase {
    func makeDeeplink() -> DeepLink {
        let head = DeepLink("Head", sender: #file)
        head.append(.init(name:"String"))
        head.append(.init(name: "Path"))
        head.append(.init(name:"String+sender", value: #file))
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
