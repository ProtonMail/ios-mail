//
//  PushNotificationServiceSubscriptionTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 08/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class PushNotificationServiceSubscriptionTests: XCTestCase {
    typealias SubscriptionSettings = APIService.PushSubscriptionSettings
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
