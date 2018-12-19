//
//  PushNotificationServiceSubscriptionTests.swift
//  ProtonMailTests - Created on 08/11/2018.
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

class PushNotificationServiceSubscriptionTests: XCTestCase {
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias Subscription = PushNotificationService.Subscription
    
    func testEquatable() {
        let settingsA = SubscriptionSettings(token: "You shall not pass", UID: "010010101101")
        let settingsB = SubscriptionSettings(token: "Welcome to Wonderland", UID: "999")
        
        XCTAssertNotEqual(Subscription.pending(settingsA), Subscription.none)
        XCTAssertNotEqual(Subscription.pending(settingsA), Subscription.reported(settingsB))
        XCTAssertNotEqual(Subscription.pending(settingsA), Subscription.pending(settingsB))
    }
    
    func testEncodeDecode() {
        let settings = SubscriptionSettings(token: "You shall not pass", UID: "010010101101")
        
        let none = Subscription.none
        let pending = Subscription.pending(settings)
        let notReported = Subscription.notReported(settings)
        let reported = Subscription.reported(settings)
        
        func encodeDecode<T: Codable>(_ value: T) throws -> T {
            let data = try PropertyListEncoder().encode(value)
            return try PropertyListDecoder().decode(T.self, from: data)
        }
        
        XCTAssertEqual(none, try? encodeDecode(none))
        XCTAssertEqual(none, try? encodeDecode(pending))
        XCTAssertEqual(none, try? encodeDecode(notReported))
        XCTAssertEqual(reported, try? encodeDecode(reported))
    }
}
