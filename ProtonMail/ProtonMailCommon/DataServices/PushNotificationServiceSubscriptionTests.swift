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
    typealias SubscriptionPack = PushNotificationService.SubscriptionsPack
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias SubscriptionWithSettings = PushNotificationService.SubscriptionWithSettings
    typealias InMemorySaver = PushNotificationServiceTests.InMemorySaver
    
    func testEquatable() {
        let settingsA = SubscriptionSettings(token: "You shall not pass", UID: "010010101101")
        let settingsB = SubscriptionSettings(token: "Welcome to Wonderland", UID: "999")
        
        XCTAssertNotEqual(SubscriptionWithSettings(settings: settingsA, state: .pending), SubscriptionWithSettings(settings: settingsB, state: .reported))
        XCTAssertNotEqual(SubscriptionWithSettings(settings: settingsA, state: .pending), SubscriptionWithSettings(settings: settingsB, state: .pending))
    }
    
    func testEncodeDecode() {
        let settings = SubscriptionSettings(token: "You shall not pass", UID: "010010101101")
        
        let pending = SubscriptionWithSettings(settings: settings, state: .pending)
        let notReported = SubscriptionWithSettings(settings: settings, state: .notReported)
        let reported = SubscriptionWithSettings(settings: settings, state: .reported)
        
        func encodeDecode<T: Codable>(_ value: T) throws -> T {
            let data = try PropertyListEncoder().encode(value)
            return try PropertyListDecoder().decode(T.self, from: data)
        }
        
        XCTAssertEqual(pending, try? encodeDecode(pending))
        XCTAssertEqual(notReported, try? encodeDecode(notReported))
        XCTAssertEqual(reported, try? encodeDecode(reported))
    }
    
    func testSet() {
        let tokenA = "AAAAAAAA"
        let uid1 = "11111111"
        
        let tokenB = "BBBBBBBB"
        let uid2 = "22222222"
        
        let settingsA1 = SubscriptionSettings(token: tokenA, UID: uid1)
        let settingsA2 = SubscriptionSettings(token: tokenA, UID: uid2)
        let settingsB1 = SubscriptionSettings(token: tokenB, UID: uid1)
        
        var settingsB1Kit = settingsB1
        try? settingsB1Kit.generateEncryptionKit()
        
        let A1p = SubscriptionWithSettings(settings: settingsA1, state: .pending)
        let A1r = SubscriptionWithSettings(settings: settingsA1, state: .reported)
        let A2r = SubscriptionWithSettings(settings: settingsA2, state: .reported)
        let B1r = SubscriptionWithSettings(settings: settingsB1, state: .reported)
        
        let setSubscriptions = Set(A1p, A1r, A2r, A2r, B1r)
        XCTAssertEqual(setSubscriptions, Set(A1p, A2r, B1r))
        
        XCTAssert(setSubscriptions.contains(A1p))
        XCTAssert(setSubscriptions.contains(A2r))
        XCTAssert(setSubscriptions.contains(B1r))
        
        let setSettings = Set(settingsA1, settingsA1, settingsA2, settingsB1, settingsB1Kit)
        XCTAssertEqual(setSettings, Set(settingsA1, settingsA2, settingsB1))
        
        XCTAssert(setSettings.contains(settingsA1))
        XCTAssert(setSettings.contains(settingsA2))
        XCTAssert(setSettings.contains(settingsB1))
    }
    
    
    func testPackInsert() {
        let pack = SubscriptionPack(InMemorySaver<Set<SubscriptionWithSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>())
        let tokenA = "AAAAAAAA"
        let tokenB = "BBBBBBBB"
        let uid1 = "11111111"
        let uid2 = "22222222"
        
        let A1p = SubscriptionWithSettings(settings: .init(token: tokenA, UID: uid1), state: .pending)
        let A1r = SubscriptionWithSettings(settings: .init(token: tokenA, UID: uid1), state: .reported)
        let A2r = SubscriptionWithSettings(settings: .init(token: tokenA, UID: uid2), state: .reported)
        let B1r = SubscriptionWithSettings(settings: .init(token: tokenB, UID: uid2), state: .reported)
        
        pack.insert(Set([A1p, B1r]))
        XCTAssertEqual(pack.subscriptions, Set(A1p, B1r))
        
        pack.insert(Set([A1r]))
        XCTAssertEqual(pack.subscriptions, Set(A1p, B1r))
        
        pack.insert(Set([A2r]))
        XCTAssertEqual(pack.subscriptions, Set(A1p, B1r, A2r))
    }
    
    func testPackUpdate() {
        let pack = SubscriptionPack(InMemorySaver<Set<SubscriptionWithSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>())
        let tokenA = "AAAAAAAA"
        let tokenB = "BBBBBBBB"
        let uid1 = "11111111"
        let uid2 = "22222222"
        
        let settingsA1 = SubscriptionSettings(token: tokenA, UID: uid1)
        let settingsA2 = SubscriptionSettings(token: tokenA, UID: uid2)
        let settingsB1 = SubscriptionSettings(token: tokenB, UID: uid1)
        let A1p = SubscriptionWithSettings(settings: settingsA1, state: .pending)
        let A1r = SubscriptionWithSettings(settings: settingsA1, state: .reported)
        let A2r = SubscriptionWithSettings(settings: settingsA2, state: .reported)
        let B1r = SubscriptionWithSettings(settings: settingsB1, state: .reported)
        
        pack.insert(Set(A1p, B1r))
        
        // existing settings
        pack.update(settingsA1, toState: .reported)
        XCTAssertEqual(pack.subscriptions, Set(A1r, B1r))
        
        // non-existing settings
        pack.update(settingsA2, toState: .reported)
        XCTAssertEqual(pack.subscriptions, Set(A1r, B1r, A2r))
    }
    
    func testPackOutdateRemoved() {
        let pack = SubscriptionPack(InMemorySaver<Set<SubscriptionWithSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>())
        let tokenA = "AAAAAAAA"
        let tokenB = "BBBBBBBB"
        let uid1 = "11111111"
        let uid2 = "22222222"
        
        let settingsA1 = SubscriptionSettings(token: tokenA, UID: uid1)
        let settingsA2 = SubscriptionSettings(token: tokenA, UID: uid2)
        let settingsB1 = SubscriptionSettings(token: tokenB, UID: uid1)
        let A1p = SubscriptionWithSettings(settings: settingsA1, state: .pending)
        let B1r = SubscriptionWithSettings(settings: settingsB1, state: .reported)
        
        pack.insert(Set(A1p, B1r))
        
        // existing settings
        pack.outdate(Set(settingsA1))
        XCTAssertEqual(pack.subscriptions, Set(B1r))
        XCTAssertEqual(pack.outdatedSettings, Set(settingsA1))
        
        // non-existing settings
        pack.update(settingsA1, toState: .pending)
        pack.outdate(Set(settingsB1))
        XCTAssertEqual(pack.subscriptions, Set(A1p))
        XCTAssertEqual(pack.outdatedSettings, Set(settingsA1, settingsB1))
        
        pack.removed(settingsB1)
        XCTAssertEqual(pack.outdatedSettings, Set(settingsA1))
    }
    
    func testPackSettings() {
        let pack = SubscriptionPack(InMemorySaver<Set<SubscriptionWithSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>(),
                                    InMemorySaver<Set<SubscriptionSettings>>())
        let tokenA = "AAAAAAAA"
        let tokenB = "BBBBBBBB"
        let uid1 = "11111111"
        let uid2 = "22222222"
        
        let settingsA1 = SubscriptionSettings(token: tokenA, UID: uid1)
        let settingsA2 = SubscriptionSettings(token: tokenA, UID: uid2)
        let settingsB1 = SubscriptionSettings(token: tokenB, UID: uid1)
        let A1p = SubscriptionWithSettings(settings: settingsA1, state: .pending)
        let A1r = SubscriptionWithSettings(settings: settingsA1, state: .reported)
        let A2r = SubscriptionWithSettings(settings: settingsA2, state: .reported)
        let B1r = SubscriptionWithSettings(settings: settingsB1, state: .reported)
        
        pack.insert(Set([A1p, B1r, A2r]))
        pack.update(settingsA1, toState: .reported)
        pack.outdate(Set(settingsB1))
        XCTAssertEqual(pack.subscriptions, Set(A1r, A2r))
        XCTAssertEqual(pack.settings(), Set(settingsA1, settingsA2))
    }
}

extension Set where Element == PushNotificationService.SubscriptionWithSettings {
    init(_ items: Element...) {
        self.init(items)
    }
}
extension Set where Element == PushNotificationService.SubscriptionSettings {
    init(_ items: Element...) {
        self.init(items)
    }
}
