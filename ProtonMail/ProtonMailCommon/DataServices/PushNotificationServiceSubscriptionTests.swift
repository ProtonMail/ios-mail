//
//  PushNotificationServiceSubscriptionTests.swift
//  ProtonMailTests - Created on 08/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
